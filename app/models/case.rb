class Case < ApplicationRecord
    before_save :generate_external_uuid
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
        (data.first[0][0]..data.keys.last[0]).step(frequency) do |selectyears|
            refrange << selectyears
        end
        refrange << data.keys.last[0] unless refrange.last==data.keys.last[0]
        result={}
        data.each do |key, value|
            hashkey=[]
            hashkey << key[0]
            hashkey << key[1]
            result[hashkey]='%.2f' % value.to_d if refrange.include?key.first
        end
        # Hash with year, valuetype.
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
        # Create the annual automatic cashbalances
        @balancevalue=0
        self.simulations.where(:valuetype => [1,2,3]).group(:t).sum(:value).each do |key, value|
            self.simulations.create(valuetype: 3, sourcetype: 0, t: key, value: -1 * value) unless value==0
            @balancevalue=@balancevalue+value
            self.simulations.create(valuetype: 10, sourcetype: 0, t: key, value: @balancevalue)
        end
    end

    private
    def generate_external_uuid
        self.external_id = SecureRandom.uuid
    end
end