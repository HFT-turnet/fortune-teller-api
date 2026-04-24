require "test_helper"

class TimesliceTest < ActiveSupport::TestCase
  # initialize: creates a Timeslice with an empty tvs array
  test "initialize creates empty tvs array" do
    ts = Timeslice.new
    assert_equal [], ts.tvs
  end

  test "initialize accepts hash attributes" do
    ts = Timeslice.new(t: 2025, i: 0.02)
    assert_equal 2025, ts.t
    assert_equal 0.02, ts.i
  end

  # tvs_attributes=: builds Timevalue objects from an array of attribute hashes
  test "tvs_attributes= pushes Timevalue objects into tvs" do
    ts = Timeslice.new(t: 2025, i: 0.02)
    ts.tvs_attributes = [
      { label: "Rent", cto: 1000, fromt: 2020, tot: 2050, inflation: 0.02 }
    ]
    assert_equal 1, ts.tvs.length
    assert_instance_of Timevalue, ts.tvs.first
    assert_equal "Rent", ts.tvs.first.label
  end

  test "tvs_attributes= pushes multiple Timevalue objects" do
    ts = Timeslice.new(t: 2025, i: 0.02)
    ts.tvs_attributes = [
      { label: "Rent",  cto: 1000, fromt: 2020, tot: 2050, inflation: 0.02 },
      { label: "Food",  cto: 500,  fromt: 2020, tot: 2050, inflation: 0.015 }
    ]
    assert_equal 2, ts.tvs.length
  end

  # fillvars: fills nil fromt/tot with defaults (0 / 1400)
  test "fillvars sets fromt to 0 when nil" do
    ts = Timeslice.new(t: 2025)
    ts.tvs << Timevalue.new(cto: 500)
    ts.fillvars
    assert_equal 0, ts.tvs.first.fromt
  end

  test "fillvars sets tot to 1400 when nil" do
    ts = Timeslice.new(t: 2025)
    ts.tvs << Timevalue.new(cto: 500)
    ts.fillvars
    assert_equal 1400, ts.tvs.first.tot
  end

  test "fillvars does not overwrite existing fromt and tot" do
    ts = Timeslice.new(t: 2025)
    ts.tvs << Timevalue.new(cto: 500, fromt: 2000, tot: 2060)
    ts.fillvars
    assert_equal 2000, ts.tvs.first.fromt
    assert_equal 2060, ts.tvs.first.tot
  end

  # ctoinflate: applies inflation to cto for each timevalue
  test "ctoinflate inflates cto using timevalue's own inflation rate" do
    ts = Timeslice.new(t: 2025, i: 0.00)
    tv = Timevalue.new(cto: 1000.to_d, inflation: 0.1, fromt: 2020, tot: 2050)
    ts.tvs << tv
    ts.ctoinflate(2)
    # 1000 * (1 + 0.1)^2 = 1210.00
    assert_equal 1210.00.to_d, ts.tvs.first.cto
  end

  test "ctoinflate uses timeslice inflation rate when timevalue inflation is zero" do
    ts = Timeslice.new(t: 2025, i: 0.05)
    tv = Timevalue.new(cto: 1000.to_d, inflation: 0, fromt: 2020, tot: 2050)
    ts.tvs << tv
    ts.ctoinflate(1)
    # 1000 * (1 + 0.05)^1 = 1050.00
    assert_equal 1050.00.to_d, ts.tvs.first.cto
  end

  test "ctoinflate does not change cto when both inflation rates are zero" do
    ts = Timeslice.new(t: 2025, i: 0.0)
    tv = Timevalue.new(cto: 1000.to_d, inflation: 0, fromt: 2020, tot: 2050)
    ts.tvs << tv
    ts.ctoinflate(5)
    assert_equal 1000.to_d, ts.tvs.first.cto
  end

  # list: returns only the timevalues active at the timeslice's current t
  test "list returns timevalues active at current t" do
    ts = Timeslice.new(t: 2025, i: 0.0)
    ts.tvs << Timevalue.new(label: "Active", cto: 1000, fromt: 2020, tot: 2030)
    ts.tvs << Timevalue.new(label: "Future", cto: 500,  fromt: 2026, tot: 2050)
    ts.tvs << Timevalue.new(label: "Past",   cto: 200,  fromt: 2010, tot: 2024)
    result = ts.list
    assert_equal 1, result.length
    assert_equal "Active", result.first.label
  end

  test "list returns empty array when no timevalues are active" do
    ts = Timeslice.new(t: 1999, i: 0.0)
    ts.tvs << Timevalue.new(cto: 1000, fromt: 2000, tot: 2050)
    assert_empty ts.list
  end

  # ctosum: sums cto of all active timevalues
  test "ctosum returns sum of active cto values" do
    ts = Timeslice.new(t: 2025, i: 0.0)
    ts.tvs << Timevalue.new(cto: 1000.to_d, fromt: 2020, tot: 2030)
    ts.tvs << Timevalue.new(cto: 500.to_d,  fromt: 2020, tot: 2030)
    ts.tvs << Timevalue.new(cto: 200.to_d,  fromt: 2026, tot: 2050)  # not active
    assert_equal 1500.to_d, ts.ctosum
  end

  test "ctosum returns zero when no timevalues are active" do
    ts = Timeslice.new(t: 1990, i: 0.0)
    ts.tvs << Timevalue.new(cto: 1000.to_d, fromt: 2000, tot: 2050)
    assert_equal 0.to_d, ts.ctosum
  end

  # move_to: advances the timeslice to a new year, applying inflation
  test "move_to changes t to the target year" do
    ts = Timeslice.new(t: 2020, i: 0.0)
    ts.move_to(2025)
    assert_equal 2025, ts.t
  end

  test "move_to inflates cto values by the time difference" do
    ts = Timeslice.new(t: 2020, i: 0.1)
    tv = Timevalue.new(cto: 1000.to_d, inflation: 0, fromt: 2020, tot: 2050)
    ts.tvs << tv
    ts.move_to(2021)
    # 1000 * (1 + 0.1)^1 = 1100.00
    assert_equal 1100.to_d, ts.tvs.first.cto
  end

  # duplicate_all: creates a deep copy of the timeslice
  test "duplicate_all returns a new Timeslice object" do
    ts = Timeslice.new(t: 2025, i: 0.02)
    ts.tvs << Timevalue.new(cto: 1000.to_d, fromt: 2020, tot: 2050)
    copy = ts.duplicate_all
    refute_same ts, copy
  end

  test "duplicate_all deep copies timevalues" do
    ts = Timeslice.new(t: 2025, i: 0.02)
    ts.tvs << Timevalue.new(cto: 1000.to_d, fromt: 2020, tot: 2050)
    copy = ts.duplicate_all
    copy.tvs.first.cto = 9999.to_d
    assert_equal 1000.to_d, ts.tvs.first.cto  # original unchanged
  end

  # freeze: duplicates and zeroes out cto for timevalues outside fromt..tot
  test "freeze zeroes cto for timevalues outside the valid range" do
    ts = Timeslice.new(t: 2025, i: 0.0)
    ts.tvs << Timevalue.new(cto: 1000.to_d, fromt: 2030, tot: 2050)  # not yet active
    frozen = ts.freeze
    assert_equal 0, frozen.tvs.first.cto
  end

  test "freeze preserves cto for timevalues within the valid range" do
    ts = Timeslice.new(t: 2025, i: 0.0)
    ts.tvs << Timevalue.new(cto: 1000.to_d, fromt: 2020, tot: 2030)  # active
    frozen = ts.freeze
    assert_equal 1000.to_d, frozen.tvs.first.cto
  end

  test "freeze does not modify the original timeslice" do
    ts = Timeslice.new(t: 2025, i: 0.0)
    ts.tvs << Timevalue.new(cto: 500.to_d, fromt: 2030, tot: 2050)
    ts.freeze
    assert_equal 500.to_d, ts.tvs.first.cto  # original unchanged
  end
end
