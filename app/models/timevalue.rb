class Timevalue 
  
  include ActiveModel::Model
  attr_accessor :sv, :tax, :fee, :interest, :valuation, :cto, :t, :ev
  validates_presence_of :t
  validates :t, numericality: { only_integer: true }

  
  # sv = start value (i.e. begin of month)
  # tax = tax effect
  # fee = fee effect
  # interest = interest effect
  # valuation = valuation effect
  # cto = cash to/from owner effect
  # ev = value at end of period => result, not an attribute
  # t = period (i.e. end of month)
  
  # end value calculated on demand
  def calc_ev(r)
    self.interest=self.sv * r
    self.ev = self.sv.to_d + self.tax.to_d + self.fee.to_d + self.interest.to_d + self.valuation.to_d + self.cto.to_d 
  end
  
  def update(attributes)
    self.sv=attributes[:sv] unless attributes[:sv].nil?
    self.tax=attributes[:tax] unless attributes[:tax].nil?
    self.fee=attributes[:fee] unless attributes[:fee].nil?
    self.interest=attributes[:interest] unless attributes[:interest].nil?
    self.valuation=attributes[:valuation] unless attributes[:valuation].nil?
    self.cto=attributes[:cto] unless attributes[:cto].nil?
    self.t=attributes[:t] unless attributes[:t].nil?
    self.ev=attributes[:ev] unless attributes[:ev].nil?
  end

end


# attr_accessor :pv, :r, :t
# pv = present value
# fv = future value
# r = interest rate (in decimal)
# t = time

# test function for discounting.
  #  self.pv * (1+self.r)**t