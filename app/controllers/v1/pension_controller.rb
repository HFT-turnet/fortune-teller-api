class V1::PensionController < ApplicationController

# The Pension Controller is responsible to calculate all kinds of pensions (state and private)
# The "ptype" is the pension type.
# There are helpers to estimate / propose values in a similar way across the kinds
# Core data that is required is:
# - personal: birth and deathyear
# - pension: ptype, provider, startsaving, endsaving, startpayout, endpayout
# - assumptions: interest, inflation, tax, costs
# - savingvalues and credits
# - payoutvalues
# As the pension models are so different, a number of them is implemented as a separate function
    # Due to the required inputs being complex, a sample input is provided.
    def sample_input
        # The sample input data is a hash with the core data
        # This is DRV sample.
        sample_input = {
            person: {
                birthyear: 1970
            },
            pensionplan: {
                provider: "DRV-West",
                startsaving: 2000,
                endsaving: 2035,
                startpayout: 2035
            },
            drv: {
                annahmen: {
                    rentenanpassung: 0.01,
                    extrapolation: "typ"
                    },
                rentenpunkte: [
                    {
                        information1: "Rentenpunkte können als type 'status' kumuliert oder 'contribution' Jahresweise angegeben werden.",
                        information2: "Die Werte werden auf eine Zeitlinie gebracht und Individualwerte nach dem letzten kumulierten Wert ergänzt, andere Werte entfallen.",
                        information3: "Rentenpunkte müssen nicht übermittelt werden, stattdessen können SV-Gehaltswerte angegegeben werden.",
                        information4: "Die Art der Extrapolation wird durch die Annahmen bestimmt."
                    },
                    {
                        type: "status",
                        year: 2020,
                        value: 40
                    },
                    {
                        type: "contribution",
                        year: 2021,
                        value: 1.25
                    }
                ],
                sv_gehalt: [
                    {
                        information1: "SV Gehaltswerte werden an der Bemessungsgrenze abgeschnitten und in Relation zum Durchschnittsgehalt gesetzt.",
                        information2: "Werden Punkte und SV Gehalt übermittelt, werden die Punkte bevorzugt.",
                        information3: "Auch hier werden die Werte in Sequenz gebracht und ergänzen ggf bestehende Punktwerte."
                    },
                    {
                        year: 2020,
                        value: 80000
                    },
                    {
                        year: 2022,
                        value: 90000
                    }
                ]
            }
        }
        render json: sample_input
    end
# POST /pension/(:ptype)/payout
# The main function to answer the key question: "How much will I get?"
# The function is a wrapper around the specific functions for the different pension types
    def route_payout
        # The pension type is the first parameter
        ptype = params[:ptype]
        # The parameters are passed on to the specific function
        case ptype
        when "drv"
            # State pension is calculated by the state pension model
            drv_pension_payout
        when "wpv"
            # Private pensions are calculated by the private pension model
            wpv_pension_payout
        when "riester"
            # Riester pensions are calculated by the Riester pension model
            riester_pension_payout
        when "ruerup"
            # Rürup pensions are calculated by the Rürup pension model
            ruerup_pension_payout
        when "li"
            # Life insurances are calculated by the life insurance model
            life_insurance_payout
        else
            # If the pension type is not known, the function returns an error
            render json: {error: "Unknown pension type"}, status: :bad_request
        end
    end

    def drv_pension_payout
        iserror = check_params(params[:person], params[:pensionplan])
        render json: iserror unless iserror.blank?
        
        # Extract certain data or use standards
        provider=params[:pensionplan][:provider].downcase || "drv-west"
        queried_year=params[:pensionplan][:startpayout].to_i unless params[:pensionplan][:startpayout].nil?
        annahme_rentenanpassung=params.dig('drv','annahmen','rentenanpassung').to_d || 0 #unless params[:drv][:annahmen][:rentenanpassung].nil?
        
        # Prepare reply
        @assumptions=[]
        @assumptions << "Limitierung: Diese Simulation ist im frühen Entwicklungsstadium!"
                
        # Regelalter ermitteln (nur Jahre, die Übergangszeiten sind stehen in der DB.)
        regularstart=Pensionfactor.where(ptype: "drv", provider: provider, factor: "regularstart", year: params[:person][:birthyear]).first
        if regularstart.nil?
            regularstart=params[:person][:birthyear].to_i+67
        else
            regularstart=regularstart.value
        end

        # Check whether any source for rentenpunkte is given. If not, assume a standard value.
        if params[:drv].nil? or (params[:drv][:rentenpunkte].nil? and params[:drv][:sv_gehalt].nil?)
            entgeltpunkte=regularstart-params[:person][:birthyear].to_i-25
            @assumptions << "Es gab keine Information zu Rentenpunkten oder sv_gehalt, daher wird ein Verdienst auf Durchschnitt ab 25 angenommen."
            @assumptions << "Annahmenbedingte Entgeltpunkte: " + entgeltpunkte.to_s
        end
        # Obtain all available input and check necessary action.
        # übermittelte Rentenpunkte als Hash
        rentenpunkte=params.dig('drv','rentenpunkte')
        sv_gehaelter=params.dig('drv','sv_gehalt')
        # Rentenpunkte gehen vor:
        # Höchster kumulierter Rentenounkte-Wert
        unless rentenpunkte.nil?
            # Get all status entries from the hash, remove the nils and take the max year.
            rentenpunkte_kum_maxjahr=rentenpunkte.map{|k,v| k[:year] if k[:type]=="status"}.compact!.max
            rentenpunkte_kum_max=rentenpunkte.map{|k,v| k[:value] if (k[:type]=="status" and k[:year]==rentenpunkte_kum_maxjahr) }.compact!.sum
            # Addition of all contributions after the last status entry.
            rentenpunkte_iso_nachmaxjahr=rentenpunkte.map{|k,v| k[:year] if k[:type]=="contribution" and k[:year]>rentenpunkte_kum_maxjahr}.compact!.max
            rentenpunkte_iso_nachmax=rentenpunkte.map{|k,v| k[:value] if k[:type]=="contribution" and k[:year]>rentenpunkte_kum_maxjahr}.compact!.sum
            entgeltpunkte=rentenpunkte_kum_max.to_d+rentenpunkte_iso_nachmax.to_d
            # The below variable is necessary to clarify the max in the following steps.
            rentenpunktemaxjahr=rentenpunkte_iso_nachmaxjahr || rentenpunkte_kum_maxjahr
            @assumptions << "Rentenpunkte aus Statusmeldung ("+rentenpunkte_kum_maxjahr.to_s+"): " + rentenpunkte_kum_max.to_s
            @assumptions << "Rentenpunkte aus darauf folgenden Einzeljahren: " + rentenpunkte_iso_nachmax.to_s
        end
        # SV-Gehälter are used to refine rentenpunkte after the last status or to estimate them.
        unless sv_gehaelter.nil?
            # Check whether there are rentenpunkte to work with.
            if entgeltpunkte.nil?
                # Use SV-Gehälter as leading
                sv_gehaelter_nach_punkten=sv_gehaelter.clone
                sv_gehaelter_nach_punkten.delete_if { |k,v| k[:year] > regularstart } # No consideration beyond the target retirement age. 
                # Now we have a hash with the years before the retirement age.
                additionalpoints=Pensionfactor.drv_punkte_aus_svgehalt(sv_gehaelter_nach_punkten, provider)
                entgeltpunkte=additionalpoints unless additionalpoints.nil?
                @assumptions << "Rentenpunkte aus SV-Gehältern: " + additionalpoints.to_s
                rentenpunktemaxjahr=[sv_gehaelter.map{|k,v| k[:year]}.max, regularstart].min
            else
                # Use SV Gehälter for refinement.
                sv_gehaelter_nach_punkten=sv_gehaelter.clone
                sv_gehaelter_nach_punkten.delete_if { |k,v| k[:year] <= rentenpunktemaxjahr }  # Only those later than the points.
                sv_gehaelter_nach_punkten.delete_if { |k,v| k[:year] > regularstart } # No consideration beyond the target retirement age. 
                # Now we have a hash with the years after the last points entry.
                additionalpoints=Pensionfactor.drv_punkte_aus_svgehalt(sv_gehaelter_nach_punkten, provider)
                rentenpunktemaxjahr=[[sv_gehaelter.map{|k,v| k[:year]}.max,rentenpunktemaxjahr].max, regularstart].min
                entgeltpunkte=entgeltpunkte+additionalpoints unless additionalpoints.nil?
                @assumptions << "Rentenpunkte aus SV-Gehältern: " + additionalpoints.to_s
            end
        end
        # Estimate beyond the known values (with points, rather than with SV-Gehälter)
        # We need the last year with data.
        # We know the retirement age.
        # We need an assumption on the approach.
        # We could do nothing.
        # We could assume that the latest addition in points is the best iteration for the remaining years.
        # Or we take the average of all points and take this as assumption (we are missing working years)

        # Or we take one point to reflect the social average.
        missingyears=regularstart-rentenpunktemaxjahr
        @assumptions << "Geschätzte Rentenpunkte nach bekannten Werten: " + missingyears.to_s
        entgeltpunkte=entgeltpunkte+missingyears if missingyears>0
        @assumptions << "Geschätzte Rentenpunkte: " + entgeltpunkte.to_s
        
        # Replace modeldata with assumptions and log assumptions.
        entgeltpunkte=1 if entgeltpunkte.nil?
        
        # OFFEN: Regularstart: Korrektur bei 35 und 40 Jahren Beitragszeit
        

        # Rentenwert: Lookup in table per year. This value does not need to be versioned.
        rentenwert=Pensionfactor.drv_rentenwert(regularstart, provider, annahme_rentenanpassung)
        @assumptions << "Abgeleiteter Rentenwert: " + rentenwert.round(2).to_s

        # Zugangsfaktoren: Hash - the variance is stated in years.
        # This seems to be stable for the DRV. Therefore it is hardcoded here.
        zugangsfaktor = {}
            zugangsfaktor["0"]=1
            zugangsfaktor["-1"]=0.964
            zugangsfaktor["-2"]=0.928
            zugangsfaktor["-3"]=0.892
            zugangsfaktor["-4"]=0.856
            zugangsfaktor["1"]=1.060
            zugangsfaktor["2"]=1.120
            zugangsfaktor["3"]=1.180
            zugangsfaktor["4"]=1.240
            zugangsfaktor["5"]=1.3
        # Rente: Entgeltpunkte X Zugangsfaktor X Rentenartfaktor X Rentenartwert
        # Simulation in Varianten so viele wie Zugangsfaktoren erfasst sind.
        @variants={}
        zugangsfaktor.keys.each do |key|
            year=regularstart.to_i+key.to_i
            payout={}
            payout["startyear"]=year
            payout["monthly"] = (rentenwert * zugangsfaktor[key] * entgeltpunkte).round(2)
            payout["annually"] = (payout["monthly"]*12).round(2)
            @variants[year] = payout
        end
        # Queried payout is a selection of the above, therefore it needs to be in the list of keys.
        queried_year=regularstart unless queried_year.in?(@variants.keys)
        @queried_payout=@variants[queried_year]

        # Render the result
        render 'drv_pension_payout' if iserror.blank?
    end

    def wpv_pension_payout
        iserror = check_params(params[:person], params[:pensionplan])
        render json: iserror unless iserror.blank?
        # The simulation is more or less complex depending on the data provided.
        @payout={}
        @payout["standard"] = 23000
        @payout["min"] = 20000
        @payout["max"] = 25000
        render 'wpv_pension_payout' if iserror.blank?
    end

  private
    
    def check_params(person, pensionplan)
        message = "Core person data is missing. You can get sample input data with GET v1/pension/sample" if person.nil?
        message = "Core pensionplan data is missing. You can get sample input data with GET v1/pension/sample" if pensionplan.nil?
        message = "Birthyear is missing" if person[:birthyear].nil?
        return message
    end
    def drv_make_assumptions(person, pensionplan)
    end
end
