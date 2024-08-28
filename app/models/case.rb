class Case < ApplicationRecord
    before_save :generate_external_uuid
    before_save :set_nodelete_default
    has_many :simulations
    has_many :cvalues
    has_many :cslices

    # Definitions
    def sex_text
        case sex
        when 1
            return "male"
        when 2
            return "female"
        when 3
            return "diverse"
        end
    end

    # Data extraction
    def timeline(frequency, valuetype=nil)
        # Obtain the valuetype aggregated values for the case
        frequency=5 if frequency.nil?
        simulationdata=self.simulations if valuetype.nil?
        simulationdata=self.simulations.where(:valuetype => valuetype) unless valuetype.nil?
        data=simulationdata.order(:t).group(:t, :valuetype).sum(:value)
        # Output to be limited to the frequency
        refrange=[]
        (data.first[0][0]..data.keys.last[0]).step(frequency.to_i) do |selectyears|
            refrange << selectyears
        end
        refrange << data.keys.last[0] unless refrange.last==data.keys.last[0]
        # Build result hash, several entries per year to be aggregated as array.
        result={}
        data.each do |key, value|
            # Is the year in the frequency?
            if refrange.include?key.first
                line={}
                line[:valuetype]=key[1]
                line[:valuetype_text]=Simulation.valuetype_text(key[1])
                line[:value]='%.2f' % value.to_d
                result[key.first] ||= [] # Create an array for the year if it does not exist
                result[key.first] << line
                #result[key.first]=line if result[key.first].nil?
                #result[key.first]<<line unless result[key.first].nil?
            end

            # Old model
            #hashkey=[]
            #hashkey << key[0]
            #hashkey << key[1]
            #result[hashkey]='%.2f' % value.to_d if refrange.include?key.first
        end
        return result
    end

    def details(t)
        # this function is to be used to extract the details of a certain year
        # for this to work an aggregation of the simulation for the year and reference data (like drill-down on Cslice) are needed.
        # The output is to follow the following order: movements of the year, followed by the automatic references, followed by balances.
        # Obtain the valuetype aggregated values for the case
        simdata=self.simulations.where(:t=>t).order(:valuetype)
        # Instantiate the result as hash
        result={}
        lines={}
        log=[]
        # For output first extract "pure" simvalues
        simdata.each_with_index do |simvalue, index|
            line={}
            line[:valuetype]=simvalue.valuetype
            line[:valuetype_text]=simvalue.valuetype_text
            line[:sourcetype]=simvalue.sourcetype
            line[:sourcetype_text]=simvalue.sourcetype_text
            line[:value]='%.2f' % simvalue.value.to_d
            if simvalue.sourcetype==0
                # Get the value only for automated postings
                log << simvalue.valuetype.to_s + " | " + simvalue.valuetype_text + " | " + simvalue.value.to_s
            elsif simvalue.sourcetype==1
                # For simulated cvalues, we want to get the value but also the label.
                log << simvalue.valuetype.to_s + " | " + simvalue.valuetype_text + " | " + Cvalue.find_by_id(simvalue.sourceid).label + " | " + simvalue.value.to_s
                line[:label]=Cvalue.find_by_id(simvalue.sourceid).label
            elsif simvalue.sourcetype==2
                # Cover the Cslcices
                # For Cslice we need to check in with the reference and add the details to the result.
                # Cslices contain a number of cvalues that are aggregated when executing the simulation of them.
                # Get Cslice
                cslice=Cslice.find_by_id(simvalue.sourceid)
                log << "---------------"
                log << "Cslice: " + cslice.label + " | " + simvalue.value.to_s
                cslice_details={}
                cslice.cvalues.each_with_index do |cvalue, index2|
                    log << "Cvalue: " + cvalue.label + " | " + cvalue.timemorph_cto(t).to_s
                    cslice_line={}
                    cslice_line[:label]=cvalue.label
                    cslice_line[:value]='%.2f' % cvalue.timemorph_cto(t).to_d
                    cslice_details[index2]=cslice_line
                end
                line[:cslice]=cslice_details
                log << "---------------"
            elsif simvalue.sourcetype==3
                # Cover the Cflows
                # For Cflow we need to check in with the reference and add the details to the result.
            elsif simvalue.sourcetype==4
                # Cover the CPensionflows
                # For CPensionflow we need to check in with the reference and add the details to the result.
            end
            lines[index]=line
        end
        #return log
        return lines
    end

    # Data consistency and modules
    def simulate_cashbalance
        # The cashbalance is a special case (similar to a Cvalue) that is generated from the Simulation and that 
        # balances the cashflow from income, expense and other cashflow sources.
        # Reset existing balance
        self.simulations.where(:sourcetype => 0).where(:valuetype => [3,10]).destroy_all
        # It is possible to set the balance of cash in a certain year to a certain value. This is to correct for gaps in the financial history.
        # These values have sourcetype 1, cvaluetype 4 and are simulated as type 10.
        known_values=self.simulations.where(:sourcetype => 1).where(:valuetype => 10)
        known_values_years=known_values.pluck(:t)
        # Create the annual automatic cashbalances
        @balancevalue=0
        self.simulations.where(:valuetype => [1,2,3]).group(:t).sum(:value).each do |key, value|
            self.simulations.create(valuetype: 3, sourcetype: 0, t: key, value: -1 * value) unless value==0
            @balancevalue=@balancevalue+value
            # Do we have a known value for this year?
            @balancevalue=known_values.where(:t => key).first.value if key.in?(known_values_years)
            # Only write a fresh value if it is not known by explicit statement.
            self.simulations.create(valuetype: 10, sourcetype: 0, t: key, value: @balancevalue) unless key.in?(known_values_years)
        end
        # Make sure that any remaining balance is continued until simulation end.
        cashbalance_years=self.simulations.where(:valuetype => 10).pluck(:t)
        self.byear..self.dyear do t
            unless t.in?(cashbalance_years)
                # Let us see whether we have a balance value to fill a gap.
                if (t-1).in?(cashbalance_years)
                    self.simulations.create(valuetype: 10, sourcetype: 0, t: t, value: self.simulations.where(:valuetype => 10, :t => t-1).first.value)
                end
            end
        end
    end

    # Deletion of case and all data
    def delete_all
        # Destroy simulations
        self.simulations.destroy_all
        # Destroy Cvalues, Cslices, Cflows, CPensionFlows
        self.cvalues.destroy_all
        self.cslices.destroy_all
        #@case.cflows.destroy_all
        #@case.cpensionflows.destroy_all
        # Destroy the case
        self.destroy
        puts "Deleted case with id #{self.external_id}."
    end

    private
    def set_nodelete_default
        self.nodelete=false if self.nodelete.nil?
    end
    def generate_external_uuid
        self.external_id = SecureRandom.uuid if self.external_id.nil?
    end
end