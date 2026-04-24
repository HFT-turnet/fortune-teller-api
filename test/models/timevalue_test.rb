require "test_helper"

class TimevalueTest < ActiveSupport::TestCase
  # fixvarformat: converts string attribute values to the appropriate types
  test "fixvarformat converts t to integer" do
    tv = Timevalue.new(t: "2025", sv: "0", cto: "0", ev: "0")
    tv.fixvarformat
    assert_equal 2025, tv.t
  end

  test "fixvarformat converts sv to decimal" do
    tv = Timevalue.new(t: "2025", sv: "1234.5", cto: "0", ev: "0")
    tv.fixvarformat
    assert_equal 1234.5.to_d, tv.sv
  end

  test "fixvarformat converts optional fields when present" do
    tv = Timevalue.new(t: "2025", sv: "0", cto: "0", ev: "0",
                       tax: "10", fee: "5", interest: "0.03", valuation: "100")
    tv.fixvarformat
    assert_equal 10.to_d, tv.tax
    assert_equal 5.to_d, tv.fee
    assert_equal 0.03.to_d, tv.interest
    assert_equal 100.to_d, tv.valuation
  end

  test "fixvarformat leaves nil optional fields as nil" do
    tv = Timevalue.new(t: "2025", sv: "0", cto: "0", ev: "0")
    tv.fixvarformat
    assert_nil tv.tax
    assert_nil tv.fee
    assert_nil tv.interest
    assert_nil tv.valuation
  end

  # setev: calculates end value from start value and all movements
  test "setev calculates ev as sv plus movements when checksum is nonzero" do
    tv = Timevalue.new(t: 2025, sv: 1000.to_d, cto: 100.to_d, ev: 0.to_d,
                       tax: 0.to_d, fee: 0.to_d, interest: 0.to_d, valuation: 0.to_d)
    tv.setev
    # ev = sv + tax + fee + interest + valuation - cto = 1000 + 0 + 0 + 0 + 0 - 100 = 900
    assert_equal 900.to_d, tv.ev
  end

  test "setev does not change ev when checksum is already zero" do
    # checksum = sv + tax + fee + interest + valuation - cto + ev = 0
    # 100 + 0 + 0 + 0 + 0 - 100 + 0 = 0
    tv = Timevalue.new(t: 2025, sv: 100.to_d, cto: 100.to_d, ev: 0.to_d,
                       tax: 0.to_d, fee: 0.to_d, interest: 0.to_d, valuation: 0.to_d)
    tv.setev
    # checksum = 100 + 0 + 0 + 0 + 0 - 100 + 0 = 0, so ev unchanged
    assert_equal 0.to_d, tv.ev
  end

  test "setev includes interest and valuation in ev calculation" do
    tv = Timevalue.new(t: 2025, sv: 1000.to_d, cto: 0.to_d, ev: 0.to_d,
                       tax: 0.to_d, fee: -10.to_d, interest: 30.to_d, valuation: 0.to_d)
    tv.setev
    # ev = 1000 + 0 + (-10) + 30 + 0 - 0 = 1020
    assert_equal 1020.to_d, tv.ev
  end

  # calc_ev: computes ev using market rate (rm), interest rate (r) and fee rate (rf)
  test "calc_ev sets interest valuation fee and ev" do
    tv = Timevalue.new(t: 2025, sv: 1000.to_d, cto: 0.to_d, ev: 0.to_d,
                       tax: 0.to_d, fee: 0.to_d, interest: 0.to_d, valuation: 0.to_d)
    tv.calc_ev(0.05, 0.03, 0.01)
    # interest = sv * r = 1000 * 0.03 = 30
    # valuation = sv * rm = 1000 * 0.05 = 50
    # fee = sv * rf = 1000 * 0.01 = 10
    # ev = sv + tax + fee + interest + valuation + cto = 1000 + 0 + 10 + 30 + 50 + 0 = 1090
    assert_equal 30.to_d, tv.interest
    assert_equal 50.to_d, tv.valuation
    assert_equal 10.to_d, tv.fee
    assert_equal 1090.to_d, tv.ev
  end

  # update: selectively updates attributes
  test "update changes only the given attributes" do
    tv = Timevalue.new(t: 2025, sv: 1000.to_d, cto: 200.to_d, ev: 0.to_d)
    tv.update(sv: 2000.to_d)
    assert_equal 2000.to_d, tv.sv
    assert_equal 200.to_d, tv.cto  # unchanged
    assert_equal 2025,      tv.t   # unchanged
  end

  test "update with nil value does not change attribute" do
    tv = Timevalue.new(t: 2025, sv: 500.to_d, cto: 0.to_d, ev: 0.to_d)
    tv.update(sv: nil)
    assert_equal 500.to_d, tv.sv
  end
end
