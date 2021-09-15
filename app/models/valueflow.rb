class Valueflow 
  
  include ActiveModel::Model
  attr_accessor :label, :r,:periods,:from,:to,:tvs
  # tv is label for nested valueseries
    # tvs are Timevalues
    # label = description / name of a valueflow
    # r = interest rate per period
    # periods = number of periods with rate r
    # there is a two value mode that contains many periods in between (Zeitwertberechnung)
    # from = to be used for interim storage t0=from
    # to = to be used for interim storage t1=to
  
    #attr_accessor :order_lines, :name

    def initialize(*params)
      self.tvs = []
      # Add a startingpoint
      @tvs.push(Timevalue.new( :t=>0, :sv=>0))
      super
    end
    
    # Timevalue attributes
    # sv = start value (i.e. begin of month)
    # tax = tax effect
    # fee = fee effect
    # interest = interest effect
    # valuation = valuation effect
    # cto = cash to/from owner effect
    # ev = value at end of period => result, not an attribute
    # t = period (i.e. end of month)
    
    # Set one or a series of timevalues
    #d=Timevalue.new(:pv=>100, :r=>0.02, :t=>5)
    #tr.tvs_attributes=([{:sv=>100, :r=>0.02, :t=>5},{:pv=>10044, :r=>0.04, :t=>3}])
    
    def tvs_attributes=(attributes)
      attributes.each do |tvs_params|
        @tvs.push(Timevalue.new(tvs_params))
      end
    end
    
    # Sorts the timevalues by t
    def timesort
      self.tvs=self.tvs.sort_by {|tv| tv.t}
    end
    
    # Delete duplicate timeline records (even if data gets lost)
    def cleantimeline
      # to be implemented
    end
    
    def buildseries
      self.timesort
      (self.mint..self.maxt).each do |i|
        # Add Timevalue if not exists
        getorcreate_tv_at_t(i)
      end
      self.timesort
      
      # Timeseries is complete, now values need to be recalculated
      (self.mint..self.maxt).each do |i|
        self.tvs[i].calc_ev(self.r.to_d)
        self.tvs[i+1].sv=self.tvs[i].ev unless i==self.maxt
      end
    end
    
    #Return Timevalue at t=x
    def gettv_at_t(tparam)
      return self.tvs.select {|tv| tv.t == tparam }.first 
    end
    
    # Create empty timevalue at t=x if not exists
    def getorcreate_tv_at_t(tparam)
      result=self.tvs.select {|tv| tv.t == tparam } 
      @tvs.push(Timevalue.new( :t=> tparam )) if result==[]
      return self.tvs.select {|tv| tv.t == tparam }.first
    end
    
    # Min and Max Timevalues in the Valueflow
    def mint
      return self.tvs.sort_by {|tv| tv.t}.first.t
    end
    def maxt
      return self.tvs.sort_by {|tv| tv.t}.last.t
    end
    
    
    # Special case for simple up and down timevalues (only two tvs)
    def setTwoPeriodEv
      #self.tvs.first.sv*(1+self.r)^self.periods
      self.tvs.last.ev=self.tvs.first.sv*(1+self.r)**self.periods
    end
  
    # Old
    def valid?
      parent_valid = super
      children_valid = tvs.map(&:valid?).all?
      tvs.each do |ol| 
        ol.errors.each do |attribute, error|
          errors.add(:tv_attributes, error)
        end
      end
      errors[:tv_attributes].uniq!
      parent_valid && children_valid
  end
  
  
  #https://coderwall.com/p/kvsbfa/nested-forms-with-activemodel-model-objects
  #def tv_attributes=(attributes)
  #  @tv ||= []
  #  attributes.each do |i, tv_params|
  #    @tv.push(Timevalue.new(tv_params))
  #  end
  #end

end
