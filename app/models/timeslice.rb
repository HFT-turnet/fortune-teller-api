class Timeslice 
  
  include ActiveModel::Model
  attr_accessor :t, :tvs, :i, :disclaimer, :source, :info
    # tvs are (named) Timevalues
    # t = point in time (typical years)
    # i = inflation
    # info
    # disclaimer
    # source

## Principle definitiions

    def initialize(*params)
      self.tvs = []
      # Add a startingpoint
      #@tvs.push(Timevalue.new( :t=>0, :sv=>0))
      super
    end
        
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
      self.tvs.each do |tv|
        if tv.inflation.nil? or tv.inflation==0 then
          # Timevalue has no specific rate, check overall rate
          inflation = 0 if self.i.nil? or self.i==0
          inflation = self.i.to_d
        else
          inflation = tv.inflation.to_d
        end
        unless inflation==0 then
          tv.cto=(tv.cto.to_d*(1+inflation.to_d)**tdiff).round(2)
        end
      end
    end

## Practical Use of definitions

    def list
      self.fillvars
      # Get all Lines at point in time selected in timeslice
      return self.tvs.select {|tv| tv.fromt.to_i <= self.t.to_i and tv.tot.to_i >= self.t.to_i  }
    end
        
    def ctosum
      self.fillvars
      # Sum of all cto values in the timeslice at current time
      # return self.tvs.sum {|tv| tv.cto }
      return self.tvs.select {|tv| tv.fromt.to_i <= self.t.to_i and tv.tot.to_i >= self.t.to_i  }.sum {|tv| tv.cto.to_d }.round(2)
    end
    
    def move_to(tx)
      # Changes Timeslice to t=tx
      tdiff=tx.to_i - t.to_i
      self.t=tx
      self.ctoinflate(tdiff)
    end

    def duplicate_all
      # this method is used to duplicate the timeslice and all timevalues in it
      newversion=self.dup
      newversion.tvs=[]
      self.tvs.each do |t|
        a=Timevalue.new(t.as_json)
        newversion.tvs << a
      end
      return newversion
    end

    def freeze
      # this method is used to duplicate a timeslice and only keep values in timevalues that are valid in that period
      newversion=self.dup
      newversion.tvs=[]
      self.tvs.each do |t|
        a=Timevalue.new(t.as_json)
        a.cto=0 if (a.fromt.to_i > self.t.to_i or a.tot.to_i < self.t.to_i )
        newversion.tvs << a
      end
      return newversion
    end
end
