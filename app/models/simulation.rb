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

    # Sourcetype
    # 0: Internal automatism
    # 1: Cvalue (a value in time with limits and characteristics)
    # 2: Cslice (many individual timevalues that are to be treated in aggregation)
    # 3: Cflow (a flow over a certain timeframe, i.e. debt, fund, other)
    # 4: CPensionflow (specific to pensions, similar to Cflow, but potentially non-currency)

    # Data extraction

end
