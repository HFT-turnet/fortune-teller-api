class Envelope  
  
  include ActiveModel::Model
  attr_accessor :start, :end, :expenses, :incomes, :assets

    def initialize(*params)
      self.tvs = []
      # Add a startingpoint
      #@tvs.push(Timevalue.new( :t=>0, :sv=>0))
      super
    end
        
aaend