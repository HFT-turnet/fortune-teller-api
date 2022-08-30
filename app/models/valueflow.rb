class Valueflow 
  
  include ActiveModel::Model
  attr_accessor :label, :type, :r,:rm,:rf , :annuity, :periods,:from,:to,:tvs
  # tv is label for nested valueseries
    # tvs are Timevalues
    # label = description / name of a valueflow
    # type can be "debt", "current", "asset"
    # r = interest rate per period
    # rm = market valuation per period
    # rf = fee rate
    # annuity = contractual annuity / periodic cash pay (cto+interest+fee)
    # periods = number of periods with rate r
    # there is a two value mode that contains many periods in between (Zeitwertberechnung)
    # from = to be used for interim storage t0=from
    # to = to be used for interim storage t1=to
  
    #attr_accessor :order_lines, :name

    def initialize(*params)
      self.tvs = []
      # Add a startingpoint
      #@tvs.push(Timevalue.new( :t=>0, :sv=>0))
      super
    end
    
    def initialfix
      # Format transition from json
      self.r=self.r.to_d
      self.rm=self.rm.to_d
      self.rf=self.rf.to_d
      self.periods=self.periods.to_i # set to 0 if not yet available
      # Approximate end of series
      if periods==0 then
        # Implementation OPEN
      end
      # set last timevalue
      self.getorcreate_tv_at_t(periods)
      # Fix existing timevalues
      self.tvs.each do |tv|
        tv.fixvarformat
      end
      # Complete series
      self.buildseries     
    end
    
    def debtcalc
      self.timesort
      (self.mint..self.maxt).each do |i|
        self.tvs[i].interest=(self.tvs[i].sv * self.r).round(2)
        self.tvs[i].cto=self.tvs[i].cto-self.annuity.to_d unless i==0 #annuity only in year 1
        self.tvs[i].setev
        self.tvs[i+1].sv=self.tvs[i].ev unless i==self.maxt
      end
    end
    
    def assetcalc
      self.timesort
      (self.mint..self.maxt).each do |i|
        self.tvs[i].interest=(self.tvs[i].sv * self.r).round(2)
        self.tvs[i].valuation=(self.tvs[i].sv * self.rm).round(2)
        self.tvs[i].fee=(self.tvs[i].sv * self.rf).round(2)
        self.tvs[i].cto=self.tvs[i].cto-self.annuity.to_d unless i==0 #annuity only in year 1
        self.tvs[i].setev
        self.tvs[i+1].sv=self.tvs[i].ev unless i==self.maxt
      end
    end
    
    def payallout(cto, inflation)
      return "too many values" if self.maxt>self.mint
      remainingfunds=self.tvs[0].sv
      t=0
      while remainingfunds+cto>0
        self.tvs[t].cto=cto*(1+inflation)**t
        self.tvs[t].calc_ev(self.rm, self.r, self.rf)
        self.tvs[t].fixvarformat
        t+=1
        getorcreate_tv_at_t(t)
        self.tvs[t].sv=self.tvs[t-1].ev
        remainingfunds=self.tvs[t].sv
      end
      #self.initialfix
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
    
    # Build a series to fill all timevalues between start and end
    def buildseries
      self.timesort
      (self.mint..self.maxt).each do |i|
        # Add Timevalue if not exists
        getorcreate_tv_at_t(i)
        self.tvs[i].fixvarformat
      end
      self.updateseries
    end
    
    # Update the SV/EV pairs of a series
    def updateseries
      self.timesort
      (self.mint..self.maxt).each do |i|
        #self.tvs[i].setev
        self.tvs[i].calc_ev(self.r, self.rm, self.rf)
        #self.tvs[i].tax=-0.25 * self.r
        self.tvs[i].setev
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
    def twoperiodcomplete
      #self.tvs.first.sv*(1+self.r)^self.periods
      self.r=self.r.to_d
      self.tvs.each do |tv|
        tv.fixvarformat
      end
      # Set ev where it is missing
      periods=self.tvs.last.t-self.tvs.first.t
      if self.tvs.first.ev.blank? then
        self.tvs.first.ev=(self.tvs.last.ev*(1+self.r)**periods).round(2)
      else
        self.tvs.last.ev=(self.tvs.first.ev*(1+self.r)**periods).round(2)
      end
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
