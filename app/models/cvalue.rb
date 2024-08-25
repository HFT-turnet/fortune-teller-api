class Cvalue < ApplicationRecord
    before_save :check_core_fields
    before_save :write_to_simulation
    belongs_to :case
    has_many :simulations
    belongs_to :cslice, optional: true

    ## DEFINITIONS
    # Cvaluetype: 1: Income, 2: Expense, 3: Cashbalance
    def cvaluetype_text
        case self.cvaluetype
        when 1
            return "Income"
            # This type is timemorphed if multi-year and against the base year. It would be repeated annualy when a time-span is chosen.
        when 2
            return "Expense"
            # This type is timemorphed if multi-year and against the base year. It would be repeated annualy when a time-span is chosen.
        when 3
            return "Cashbalance - " + self.cf_type_text
            # This type represents savings / credit and a savings plan. It is not timemorphed, but simulated in cash.
            # The ev is the end value in period fromt.
            # The cto is the annual value cashflow.
            # The interest is the interest rate per year, it is incurred on the prior year.
            # The inflation can carry a value. This only makes sense in case of simulating a market value element, i.e. a fund of some kind. The amount is applied on the ev without cash impact until repayment.
            # The cf_type is the cashflow type and determines which part of th Cvalue has an impact on the overall budget.
        end
    end
    def cf_type_text
        case self.cf_type
        when 1
            return "cto contains interest" # Typical for an annuity debt.
        when 2
            return "cto and interest lead to cash" # Typical for a debt balance.
        when 3
            return "cto is cash, interest is accumulated" # Typical for a savings account.
        else
            return "Unknown" # This is OK to happen, if the cf_type is not needed.
        end
    end
    
    # Simulation depending on valuetype
    def simulate #type 3 only.
        # This module was called "simulate_cashbalance" before.
        # The purpose of this is to simulate the type3 values. All other values are either taken into the simulation via their overarching module.
        # or are added with the "before_save" write_to_simulation. Function. 
        # The type 3 is capable of simple investment flows (i.e. savings account, simple debt, a kind of financial asset).

        return unless self.cvaluetype==3

        # Clear existing simulation values
        self.case.simulations.where(:sourcetype => 1).where(:sourceid => self.id).destroy_all
        # Create new simulation values
        (self.fromt..self.tot).each do |t|
            vt_interest=1 if self.ev>0
            vt_interest=2 if self.ev<0
            vt_balance=11 if self.ev>0
            vt_balance=12 if self.ev<0
            # Write first year movement (Cash out / Cash in depending on type.)
            if t==self.fromt
                # The Balance move is treated with inverse value to the balance: i.e. to have a cashbalance on something, it goes against the cashflow.
                # It is generally assumed, that the cashflows producing the ev are aggregated towards the end of the year.
                # The cto of the first year is contained in this value, it does not come extra. No interest is considered in the first year.
                self.case.simulations.create(valuetype: 3, sourcetype: 1, sourceid: self.id, t: t, value: -1*self.ev)
                newvalue=self.ev
            else
                # For all other years, we need to consider the interest rate & CTO
                interest=@priorvalue*self.interest
                newvalue=@priorvalue # This is the starting point before oprions are considered.
                # Depending on the cashflow type, interest is accumulated, contained in cto or leads to cash.
                # The movement cash is being generated here, the ev is updated at the bottom of the loop.
                case self.cf_type
                when 1
                    # Interest is part of CTO and needs to be separated out.
                    evmovement=self.cto-interest # example: -500 annuity, -100 interest, -400 remaining ev reduction.
                    # Simulation movements: CTO, Interest.
                    self.case.simulations.create(valuetype: 3, sourcetype: 1, sourceid: self.id, t: t, value: evmovement) unless evmovement==0
                    newvalue=newvalue-evmovement # The CTO effect on the ev is adverse. i.e. negative Cash to Owner decreases the debt balance.
                    # Interest (valuetype depends on kind of interest):
                    self.case.simulations.create(valuetype: vt_interest, sourcetype: 1, sourceid: self.id, t: t, value: interest)
                when 2
                    # CTO and interest are both separate cash movements.
                    # CTO:
                    self.case.simulations.create(valuetype: 3, sourcetype: 1, sourceid: self.id, t: t, value: self.cto) unless self.cto==0
                    newvalue=newvalue-self.cto # The CTO effect on the ev is adverse. i.e. Cash to Owner decreases the savings balance.
                    # Interest (valuetype depends on kind of interest):
                    self.case.simulations.create(valuetype: vt_interest, sourcetype: 1, sourceid: self.id, t: t, value: interest)
                when 3
                    # CTO generates additional movement:
                    self.case.simulations.create(valuetype: 3, sourcetype: 1, sourceid: self.id, t: t, value: self.cto) unless self.cto==0
                    newvalue=newvalue-self.cto # The CTO effect on the ev is adverse. i.e. Cash to Owner decreases the savings balance.
                    # Interest is accumulated in balance:
                    newvalue=newvalue+interest # both correct for savings and debt.
                end
                # At this stage we have generate the every year's movements and determined a newvalue after cto and interest.
            end
            # Very special case, but technically possible: Inflation is set like a market development on a fund.
            if self.inflation!=0 and not t==self.fromt
                # The "inflation" / market movement is applied to the endvalue, but not to the movement cash.
                newvalue=newvalue*(1+self.inflation)
            end
            
            # Write last year movement or manage every other case to determine the core values.
            # This would be the remaining balance with inverted value of the start of period.
            if t==self.tot
                # The endvalue is transferred into movement cash.
                self.case.simulations.create(valuetype: 3, sourcetype: 1, sourceid: self.id, t: t, value: newvalue)
                # Endvalue is zero
                self.case.simulations.create(valuetype: vt_balance, sourcetype: 1, sourceid: self.id, t: t, value: 0)
            else
                # Write balance
                self.case.simulations.create(valuetype: vt_balance, sourcetype: 1, sourceid: self.id, t: t, value: newvalue)
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
    def check_core_fields
        # Check that the fromt and tot are in the frame of the case.
        self.fromt=self.case.byear if self.fromt<self.case.byear
        self.tot=self.case.dyear if self.tot>self.case.dyear
        # Check some core logic on the entry.
        self.inflation=0 if self.inflation.nil?
        self.interest=0 if self.interest.nil?
        self.ev=0 if self.ev.nil?
        self.cto=0 if self.cto.nil?
    end
    def write_to_simulation
        # Start the simulation
        puts "Simulating CValue: #{self.id}"
        # This is only being executed for type 1 and 2 automatically. Type 3 is being executed in the simulate function.
        # It is also limited to those entries, that are not embedded in something bigger like a Cslice.
        # Clear existing simulation values
        if self.cvaluetype<3 and self.cslice_id.nil?
            self.case.simulations.where(:sourcetype => 1).where(:sourceid => self.id).destroy_all
            # Create new simulation values
            (self.fromt..self.tot).each do |t|
                self.case.simulations.create(valuetype: self.cvaluetype, sourcetype: 1, sourceid: self.id, t: t, value: self.timemorph_cto(t))
            end
        end
        if self.cvaluetype==3 and self.cslice_id.nil?
            self.simulate
        end
        if self.cvaluetype==4
            # This is a special case, where the value of the general cash-buffer is being set, rather than calculated.
            self.case.simulations.where(:sourcetype => 1).where(:sourceid => self.id).destroy_all
            self.case.simulations.create(valuetype: 10, sourcetype: 1, sourceid: self.id, t: t, value: self.ev)
        end
    end
end
