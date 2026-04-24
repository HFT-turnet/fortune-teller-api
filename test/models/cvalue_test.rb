require "test_helper"

class CvalueTest < ActiveSupport::TestCase
  # cvaluetype_text: returns the label for the cvaluetype integer
  test "cvaluetype_text returns Income for type 1" do
    cv = Cvalue.new(cvaluetype: 1)
    assert_equal "Income", cv.cvaluetype_text
  end

  test "cvaluetype_text returns Expense for type 2" do
    cv = Cvalue.new(cvaluetype: 2)
    assert_equal "Expense", cv.cvaluetype_text
  end

  test "cvaluetype_text returns a Cashbalance string for type 3" do
    cv = Cvalue.new(cvaluetype: 3, cf_type: 1)
    assert_match /Cashbalance/, cv.cvaluetype_text
  end

  # cf_type_text: returns label for the cashflow type
  test "cf_type_text returns interest description for cf_type 1" do
    cv = Cvalue.new(cf_type: 1)
    assert_match /interest/, cv.cf_type_text
  end

  test "cf_type_text returns cash description for cf_type 2" do
    cv = Cvalue.new(cf_type: 2)
    assert_match /cash/, cv.cf_type_text
  end

  test "cf_type_text returns accumulated description for cf_type 3" do
    cv = Cvalue.new(cf_type: 3)
    assert_match /accumulated/, cv.cf_type_text
  end

  test "cf_type_text returns Unknown for an unrecognised cf_type" do
    cv = Cvalue.new(cf_type: 99)
    assert_equal "Unknown", cv.cf_type_text
  end

  # timemorph_cto: returns the inflation-adjusted cto for a given year t
  test "timemorph_cto returns original cto when inflation is zero and t equals base year" do
    cv = Cvalue.new(cto: 1000.to_d, inflation: 0.to_d, t: 2025, fromt: 2020, tot: 2040)
    assert_equal "1000.00", cv.timemorph_cto(2025)
  end

  test "timemorph_cto applies inflation over multiple years" do
    cv = Cvalue.new(cto: 1000.to_d, inflation: 0.1.to_d, t: 2025, fromt: 2020, tot: 2040)
    # 1000 * (1 + 0.1)^(2027-2025) = 1000 * 1.21 = 1210.00
    assert_equal "1210.00", cv.timemorph_cto(2027)
  end

  test "timemorph_cto returns zero when t is before fromt" do
    cv = Cvalue.new(cto: 1000.to_d, inflation: 0.02.to_d, t: 2025, fromt: 2020, tot: 2040)
    assert_equal "0.00", cv.timemorph_cto(2019)
  end

  test "timemorph_cto returns zero when t is after tot" do
    cv = Cvalue.new(cto: 1000.to_d, inflation: 0.02.to_d, t: 2025, fromt: 2020, tot: 2040)
    assert_equal "0.00", cv.timemorph_cto(2041)
  end
end
