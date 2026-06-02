class Planitem < ApplicationRecord
    belongs_to :case
    has_many :cslices, dependent: :nullify
    has_many :cvalues, dependent: :nullify

    enum :category, { phase: 1, pit: 3 }

    PLAN_TYPES = {
        "ausbildung"          => 1,
        "erwerbstaetigkeit"   => 2,
        "arbeitslos"          => 3,
        "elternzeit"          => 4,
        "pflegezeit"          => 5,
        "auszeit"             => 6,
        "ruhestand"           => 7,
        "immobilie"           => 10,
        "verkauf_immobilie"   => 11,
        "investment"          => 12,
        "erbe"                => 15,
        "versorgungszahlungen" => 16
    }.freeze

    before_create :derive_category
    after_create :generate_checklist
    after_update :adjust_related_on_time_change

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
        PLANTYPE_LABELS[PLAN_TYPES.key(self.plan_type)]
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
        PLANTYPE_ICONS[PLAN_TYPES.key(self.plan_type)]
    end

    def self.plan_types_for_category(cat_key)
        is_phase = cat_key.to_s == "phase"
        PLAN_TYPES.select { |_key, value| is_phase ? value < 10 : value >= 10 }
    end

    ## Functions
    def simulate
        # We need to check on which level the linked entries are being simulated.
      
    end

    private

    def adjust_related_on_time_change
        return unless saved_change_to_fromt? || saved_change_to_tot?

        new_fromt = self.fromt
        new_tot = self.tot

        # Adjust cvalues directly linked to this planitem (not via a cslice) and re-simulate them.
        self.cvalues.where(cslice_id: nil).each do |cvalue|
            set_cvalue_times(cvalue, new_fromt, new_tot)
            cvalue.save
            cvalue.simulate
        end

        # Adjust cslice-linked cvalues, then re-simulate each cslice.
        self.cslices.each do |cslice|
            cslice.cvalues.each do |cvalue|
                set_cvalue_times(cvalue, new_fromt, new_tot)
                cvalue.save
            end
            cslice.simulate
        end

        # Re-run the case-level cash balance simulation.
        self.case.simulate_cashbalance
    end

    def set_cvalue_times(cvalue, new_fromt, new_tot)
        if cvalue.fromt == cvalue.tot
            cvalue.fromt = new_fromt
            cvalue.tot = new_fromt
        else
            cvalue.fromt = new_fromt
            cvalue.tot = new_tot
        end
    end

    def derive_category
        return if category.present?
        return unless plan_type.present?
        self.category = self.plan_type < 10 ? :phase : :pit
    end

    def generate_checklist
        return unless plan_type.present?
        plan_type_key = PLAN_TYPES.key(self.plan_type)
        return unless plan_type_key
        SimTemplate.new.create_checklist(self.case.country, self.plan_type, case_id, id)
    end

end