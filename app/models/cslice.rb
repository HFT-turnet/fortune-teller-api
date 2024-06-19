class Cslice < ApplicationRecord
    # While a cslice might contain type 1 or 2 cvalues. It carries an own valuetype which is used in simulation.
    # The integer - type map is the same as in Cvalue.
    belongs_to :case
    has_many :cvalues
    has_many :simulations

    def sync_cvalues
        # Sync the cvalues with the cslice
        self.cvalues.each do |cvalue|
            cvalue.case_id=self.case_id
            cvalue.t=self.t
            cvalue.fromt=self.case.byear if cvalue.fromt.nil?
            cvalue.tot=self.case.dyear if cvalue.tot.nil?
            cvalue.save
        end
    end

    def simulate
        # Reset existing simulations
        self.case.simulations.where(:sourcetype => 2).where(:sourceid => self.id).destroy_all
        # Simulate the cslice
        # Iterate over the full lifespan of the case
        (self.case.byear..self.case.dyear).each do |t|
            valuesum=0
            self.cvalues.each do |cvalue|
                # Get the timemorphed value. Out of range will be identified by cvalue model.
                valuesum=valuesum+cvalue.timemorph_cto(t).to_d
            end
            self.case.simulations.create(valuetype: self.cvaluetype, sourcetype: 2, sourceid: self.id, t: t, value: valuesum) unless valuesum==0
        end
    end
end
