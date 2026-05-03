class Checklist < ApplicationRecord
  belongs_to :case
  belongs_to :planitem, optional: true

  enum :status, { offen: 1, teildaten: 2, fehler: 3, erledigt: 4 }

  STATUS_LABELS = {
    "offen"     => "Offen",
    "teildaten" => "Teildaten vorhanden",
    "fehler"    => "Fehler",
    "erledigt"  => "Erledigt"
  }.freeze

  def status_text
    STATUS_LABELS[self.status]
  end
end
