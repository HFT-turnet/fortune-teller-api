class Checklist < ApplicationRecord
  belongs_to :case
  belongs_to :planitem, optional: true

  enum :status, { offen: 1, teildaten: 2, fehler: 3, erledigt: 4 }
end
