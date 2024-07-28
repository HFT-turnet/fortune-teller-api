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
        sample_input = {
            person: {
                birthyear: 1960,
                deathyear: 2040
            },
            pensionplan: {
                ptype: "drv",
                provider: "DRV",
                startsaving: 2020,
                endsaving: 2040,
                startpayout: 2040,
                endpayout: 2080
            },
            assumptions: {
                interest: 0.02,
                inflation: 0.02,
                tax: 0.25,
                costs: 0.01
            },
            savingvalues: [
                {
                    year: 2020,
                    value: 1000
                },
                {
                    year: 2040,
                    value: 10000
                }
            ],
            credits: [
                {
                    year: 2020,
                    value: 1000
                },
                {
                    year: 2040,
                    value: 10000
                }
            ]
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

    def wpv_pension_payout
        iserror = check_params(params[:person], params[:pensionplan])
        render json: iserror unless iserror.blank?
    end

  private
    
    def check_params(person, pensionplan)
        message = "Core person data is missing. You can get sample input data with GET v1/pension/sample" if person.nil?
        message = "Core pensionplan data is missing. You can get sample input data with GET v1/pension/sample" if pensionplan.nil?
        return message
    end
end
