class Planitem < ApplicationRecord
    belongs_to :case
    has_many :cslices, dependent: :nullify
    has_many :cvalues, dependent: :nullify

    # Category: 1 - life phase, 2 - change in life, 3 - investment
    def category_text
        case self.category
        when 1
            return "Life Phase"
        when 2
            return "Change in Life"
        when 3
            return "Investment"
        else
            return "Unknown"
        end
    end
end
