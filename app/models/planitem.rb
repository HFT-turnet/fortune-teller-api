class Planitem < ApplicationRecord
    belongs_to :case
    has_many :cslices, dependent: :nullify
    has_many :cvalues, dependent: :nullify

    enum :category, { phase: 1, pit: 3 }
    enum :plan_type, { ausbildung: 1, erwerbstaetigkeit: 2, arbeitslos: 3, elternzeit: 4, pflegezeit: 5, auszeit: 6, ruhestand: 7, immobilie: 10, verkauf_immobilie: 11, investment: 12, erbe: 15, versorgungszahlungen: 16 }

    before_create :derive_category
    after_create :generate_checklist

    CATEGORY_LABELS = {
        "phase"     => "Lebensphase",
        "pit"     => "Zeitpunkt"
    }.freeze

    def category_text
        CATEGORY_LABELS[self.category]
    end
    
    PLANTYPE_LABELS = {
        "ausbildung"     => "Ausbildung",
        "erwerbstaetigkeit"     => "Erwerbstätigkeit",
        "arbeitslos"     => "Arbeitslos",
        "elternzeit"     => "Elternzeit",
        "pflegezeit"     => "Pflegezeit",
        "auszeit"     => "Auszeit",
        "ruhestand"     => "Ruhestand",
        "immobilie"     => "Immobilie",
        "verkauf_immobilie"     => "Verkauf Immobilie",
        "investment"     => "Investment",
        "erbe"     => "Erbe",
        "versorgungszahlungen"     => "Versorgungszahlungen"
    }.freeze

    def plan_type_text
        PLANTYPE_LABELS[self.plan_type]
    end
    PLANTYPE_ICONS = {
        "ausbildung"     => "fas fa-graduation-cap",
        "erwerbstaetigkeit"     => "fas fa-briefcase",
        "arbeitslos"     => "fas fa-user-tie",
        "elternzeit"     => "fas fa-baby",
        "pflegezeit"     => "fas fa-heartbeat",
        "auszeit"     => "fas fa-umbrella-beach",
        "ruhestand"     => "fas fa-wheelchair",
        "immobilie"     => "fas fa-home",
        "verkauf_immobilie"     => "fas fa-house-flag",
        "investment"     => "fas fa-chart-line",
        "erbe"     => "fas fa-file-contract",
        "versorgungszahlungen"     => "fas fa-money-bill-wave"
    }.freeze

    def plan_type_icon
        PLANTYPE_ICONS[self.plan_type]
    end

    private

    def derive_category
        return if category.present?
        return unless plan_type.present?
        self.category = Planitem.plan_types[plan_type] < 10 ? :phase : :pit
    end

    def generate_checklist
        return unless plan_type.present?
        template_key = "#{Planitem.plan_types[plan_type]}_#{plan_type}"
        SimTemplate.new.create_checklist(self.case.country, template_key, case_id, id)
    end

end