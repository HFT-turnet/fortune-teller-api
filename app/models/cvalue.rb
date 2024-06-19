class Cvalue < ApplicationRecord
    before_save :write_to_simulation
    belongs_to :case
    has_many :simulations
    belongs_to :cslice, optional: true

    ## DEFINITIONS
    # Cvaluetype: 1: Income, 2: Expense, 3: Cashbalance

    # Simulation depending on valuetype
    def simulate_cashbalance
        return unless self.cvaluetype==3
        # Clear existing simulation values
        self.case.simulations.where(:sourcetype => 1).where(:sourceid => self.id).destroy_all
        # Create new simulation values
        (self.fromt..self.tot).each do |t|
            # Write first year movement
            if t==self.fromt
                # The Balance move is treated with inverse value to the balance: i.e. to have a cashbalance on something, it goes against the cashflow.
                self.case.simulations.create(valuetype: 3, sourcetype: 1, sourceid: self.id, t: t, value: -1*self.ev)
                newvalue=self.ev
            else
                # We need to consider the interest rate here
                # Write interest as income and as a deltaposition in asset.
                interest=@priorvalue*self.interest
                self.case.simulations.create(valuetype: 1, sourcetype: 1, sourceid: self.id, t: t, value: interest)
                self.case.simulations.create(valuetype: 3, sourcetype: 1, sourceid: self.id, t: t, value: -1*interest)
                newvalue=@priorvalue+interest
            end
            
            # Write last year movement or manage every other case
            if t==self.tot
                # The endvalue is transferred into movement cash.
                self.case.simulations.create(valuetype: 3, sourcetype: 1, sourceid: self.id, t: t, value: newvalue)
                # Endvalue is zero
                self.case.simulations.create(valuetype: 11, sourcetype: 1, sourceid: self.id, t: t, value: 0)
            else
                # Write balance
                self.case.simulations.create(valuetype: 11, sourcetype: 1, sourceid: self.id, t: t, value: newvalue)
                # Store the value for the next iteration
                @priorvalue=newvalue
            end
        end
    end

    # Instance functions
    def timemorph_cto(t)
        morved_cto=self.cto*(1+self.inflation)**(t-self.t)
        morved_cto=0 if t>self.tot or t<self.fromt
        return '%.2f' % morved_cto
    end

    # Write to simulation
    private
    def write_to_simulation
        puts "I would simulate this value now."
    end
end
