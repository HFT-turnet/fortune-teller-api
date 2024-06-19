class Case < ApplicationRecord
    before_save :generate_external_uuid
    has_many :simulations
    has_many :cvalues
    has_many :cslices

    # Data extraction
    def timeline(frequency)
        # Obtain the valuetype aggregated values for the case
        frequency=5 if frequency.nil?
        data=self.simulations.order(:t).group(:t, :valuetype).sum(:value)
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
        return result
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