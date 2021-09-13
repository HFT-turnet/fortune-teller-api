class Timeslice 
  
  include ActiveModel::Model
  attr_accessor :t, :tvs, :i
    # tvs are (named) Timevalues
    # t = point in time (typical years)
    # i = inflation

    def initialize(*params)
      self.tvs = []
      # Add a startingpoint
      #@tvs.push(Timevalue.new( :t=>0, :sv=>0))
      super
    end
        
    # Set one or a series of timevalues
    #d=Timevalue.new(:pv=>100, :r=>0.02, :t=>5)
    #t.tvs_attributes=([{:label=>"Einkauf", :cto=>-2000},{:label=>"Wohnen", :cto=>-10000},{:label=>"Altersheim", :cto=>-15000, :fromt=>61, :tot=>100}])
    
    def tvs_attributes=(attributes)
      attributes.each do |tvs_params|
        @tvs.push(Timevalue.new(tvs_params))
      end
    end
    
    def fillvars
      # Fill all tvs with intervals if none have been defined
      self.tvs.each do |tv|
        tv.fromt=0 if tv.fromt.nil?
        tv.tot=1400 if tv.tot.nil?
      end
    end
    
    def ctoinflate(tdiff)
      # Fill all tvs with intervals if none have been defined
      self.tvs.each do |tv|
        if tv.inflation.nil? or tv.inflation==0 then
          # Timevalue has no specific rate, check overall rate
          inflation = 0 if self.i.nil? or self.i==0
          inflation = self.i
        else
          inflation = tv.inflation
        end
        unless inflation==0 then
          tv.cto=(tv.cto*(1+inflation)**tdiff).round(2)
        end
      end
    end
    
    def list
      self.fillvars
      # Get all Lines at time selected in timeslice
      return self.tvs.select {|tv| tv.fromt <= self.t and tv.tot >= self.t  }
    end
    
    def ctosum
      self.fillvars
      # Sum of all cto values in the timeslice at. current time
      # return self.tvs.sum {|tv| tv.cto }
      return self.tvs.select {|tv| tv.fromt <= self.t and tv.tot >= self.t  }.sum {|tv| tv.cto }.round(2)
    end
    
    def slice_at(tx)
      # Returns a new Timeslice at t=tx
      tdiff=tx - self.t
      temp=self
      temp.t=tx
      temp.ctoinflate(tdiff)
      return temp
    end
  
end
