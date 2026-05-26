class Simulation < ApplicationRecord
    belongs_to :case

    # General purpose and principles:
    # The simulation table is intended to allow for querie for any point in time to receive the then-valid amounts. This can be done via the "case.details(t)" function.
    # To avoid crowding, Cslices are there to provide an aggregator to a number of CValues.
    # CValues make up the amounts as per their characteristic.
    # In order to always have a balance, there is the valuetype 10. This is the "automatic savings balance" that is generated as the balancing item for the cash balance. It is generated in the simulate_cashbalance module and should be used in the output to always have a balance.

    ## DEFINITIONS
    # Valuetype
    # 1: Income
    # 2: Expense
    # 3: Cash_Balance_Move
    # 10: Automatic Savings Balance
    # 11: Savings Balance (Cash)
    # 12: Debt Balance (Cash)
    # 13: Assets Balance (Monetary)
    # 14: Assets Balance (Non-Monetary)
    # 15: Pension Points (Non-Currency)
    def valuetype_text
        case self.valuetype
        when 1
            return "Income"
        when 2
            return "Expense"
        when 3
            return "Cash_Balance_Move"
        when 10
            return "Automatic Savings Balance"
        when 11
            return "Savings Balance (Cash)"
        when 12
            return "Debt Balance (Cash)"
        when 13
            return "Assets Balance (Monetary)"
        when 14
            return "Assets Balance (Non-Monetary)"
        when 15
            return "Pension Points (Non-Currency)"
        end
    end
    ### WHEN DO WE USE THIS?
    def self.valuetype_text(valuetype)
        case valuetype
        when 1
            return "Income"
        when 2
            return "Expense"
        when 3
            return "Cash_Balance_Move"
        when 10
            return "Automatic Savings Balance"
        when 11
            return "Savings Balance (Cash)"
        when 12
            return "Debt Balance (Cash)"
        when 13
            return "Assets Balance (Monetary)"
        when 14
            return "Assets Balance (Non-Monetary)"
        when 15
            return "Pension Points (Non-Currency)"
        end
    end

    # Sourcetype
    # 0: Internal automatism
    # 1: Cvalue (a value in time with limits and characteristics)
    # 2: Cslice (many individual timevalues that are to be treated in aggregation) => a standard cslice does not have deviations beyond its assumptions.
    # 3: not implemented - Cflow (a flow over a certain timeframe, i.e. debt, fund, other)
    # 4: CPensionflow (specific to pensions, similar to Cflow, but potentially non-currency)
    def sourcetype_text
        case self.sourcetype
        when 0
            return "Internal automatism"
        when 1
            return "Cvalue"
        when 2
            return "Cslice"
        when 3
            return "Cflow"
        when 4
            return "CPensionflow"
        end
    end

    # Data extraction

end
