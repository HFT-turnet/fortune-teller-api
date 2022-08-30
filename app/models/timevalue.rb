class Timevalue 
  
  include ActiveModel::Model
  attr_accessor :label, :sv, :tax, :fee, :interest, :valuation, :cto, :t, :ev, :fromt, :tot, :inflation
  validates_presence_of :t
  validates :t, numericality: { only_integer: true }

  
  # label = label of tv
  # 
  # sv = start value (i.e. begin of month)
  # tax = tax effect
  # fee = fee effect
  # interest = interest effect
  # valuation = valuation effect
  # cto = cash to(+)/from(-) owner effect
  # ev = value at end of period => result, not an attribute
  #
  # t = period (i.e. end of month)
  # fromt = t with first occurence of this value (inflation at t=0 as reference)
  # tot = t with last occurence of this value (inflate at t=0 as reference)
  # inflation = assumed inflation rate (decimal writing)
  
  def fixvarformat
    self.t=self.t.to_i
    self.sv=self.sv.to_d
    self.tax=self.tax.to_d unless self.tax.nil?
    self.fee=self.fee.to_d unless self.fee.nil?
    self.interest=self.interest.to_d unless self.interest.nil?
    self.valuation=self.valuation.to_d unless self.valuation.nil?
    self.cto=self.cto.to_d
    self.ev=self.ev.to_d
  end
  
  def setev
    # Check if really relevant, when series is not yet establisehd
    checksum=sv+tax.to_d+fee.to_d+interest.to_d+valuation.to_d-cto+ev #Should be 0
    # Front to end calculation
    unless checksum==0 then
      movements=tax.to_d+fee.to_d+interest.to_d+valuation.to_d-cto
      self.ev=(sv+movements).round(2)
    end
  end
  
  # end value calculated on demand
  def calc_ev(rm, r, rf)
    self.interest=self.sv.to_d * r
    self.valuation=self.sv.to_d * rm
    self.fee=self.sv.to_d*rf
    self.ev = (self.sv.to_d + self.tax.to_d + self.fee.to_d + self.interest.to_d + self.valuation.to_d + self.cto.to_d ).to_d
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