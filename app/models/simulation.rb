class Simulation < ApplicationRecord
    belongs_to :case

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
    # 2: Cslice (many individual timevalues that are to be treated in aggregation)
    # 3: Cflow (a flow over a certain timeframe, i.e. debt, fund, other)
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
