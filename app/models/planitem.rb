class Planitem < ApplicationRecord
    belongs_to :case
    has_many :cslices, dependent: :nullify
    has_many :cvalues, dependent: :nullify

    enum :category, { life_phase: 1, change_in_life: 2, investment: 3 }

    CATEGORY_LABELS = {
        "life_phase"     => "Life Phase",
        "change_in_life" => "Change in Life",
        "investment"     => "Investment"
    }.freeze

    def category_text
        CATEGORY_LABELS[self.category]
    end
end
