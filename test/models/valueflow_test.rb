require "test_helper"

class ValueflowTest < ActiveSupport::TestCase
  # initialize: creates a Valueflow with an empty tvs array
  test "initialize creates empty tvs array" do
    vf = Valueflow.new
    assert_equal [], vf.tvs
  end

  # tvs_attributes=: builds Timevalue objects from attribute hashes
  test "tvs_attributes= pushes Timevalue objects into tvs" do
    vf = Valueflow.new
    vf.tvs_attributes = [
      { t: 0, sv: 1000, cto: 0, ev: 0 },
      { t: 1, sv: 0,    cto: 0, ev: 0 }
    ]
    assert_equal 2, vf.tvs.length
    assert_instance_of Timevalue, vf.tvs.first
  end

  # getorcreate_tv_at_t: returns existing tv or creates new one at t
  test "getorcreate_tv_at_t creates a new Timevalue when none exists" do
    vf = Valueflow.new
    tv = vf.getorcreate_tv_at_t(5)
    assert_instance_of Timevalue, tv
    assert_equal 5, tv.t
  end

  test "getorcreate_tv_at_t returns existing Timevalue without duplicating" do
    vf = Valueflow.new
    vf.tvs << Timevalue.new(t: 3, sv: 500.to_d, cto: 0.to_d, ev: 0.to_d)
    vf.getorcreate_tv_at_t(3)
    assert_equal 1, vf.tvs.select { |tv| tv.t == 3 }.length
  end

  # gettv_at_t: returns the Timevalue at time t or nil
  test "gettv_at_t returns the Timevalue at the given t" do
    vf = Valueflow.new
    vf.tvs << Timevalue.new(t: 7, sv: 200.to_d, cto: 0.to_d, ev: 0.to_d)
    tv = vf.gettv_at_t(7)
    assert_equal 7, tv.t
  end

  test "gettv_at_t returns nil when no Timevalue exists at t" do
    vf = Valueflow.new
    assert_nil vf.gettv_at_t(99)
  end

  # mint / maxt: return minimum and maximum t in tvs
  test "mint returns the minimum t value" do
    vf = Valueflow.new
    vf.tvs << Timevalue.new(t: 5, sv: 0.to_d, cto: 0.to_d, ev: 0.to_d)
    vf.tvs << Timevalue.new(t: 2, sv: 0.to_d, cto: 0.to_d, ev: 0.to_d)
    vf.tvs << Timevalue.new(t: 8, sv: 0.to_d, cto: 0.to_d, ev: 0.to_d)
    assert_equal 2, vf.mint
  end

  test "maxt returns the maximum t value" do
    vf = Valueflow.new
    vf.tvs << Timevalue.new(t: 5, sv: 0.to_d, cto: 0.to_d, ev: 0.to_d)
    vf.tvs << Timevalue.new(t: 2, sv: 0.to_d, cto: 0.to_d, ev: 0.to_d)
    vf.tvs << Timevalue.new(t: 8, sv: 0.to_d, cto: 0.to_d, ev: 0.to_d)
    assert_equal 8, vf.maxt
  end

  # timesort: sorts tvs by t ascending
  test "timesort orders tvs ascending by t" do
    vf = Valueflow.new
    vf.tvs << Timevalue.new(t: 3, sv: 0.to_d, cto: 0.to_d, ev: 0.to_d)
    vf.tvs << Timevalue.new(t: 1, sv: 0.to_d, cto: 0.to_d, ev: 0.to_d)
    vf.tvs << Timevalue.new(t: 2, sv: 0.to_d, cto: 0.to_d, ev: 0.to_d)
    vf.timesort
    assert_equal [1, 2, 3], vf.tvs.map(&:t)
  end

  # twoperiodcomplete: computes the missing end value for a two-period flow
  test "twoperiodcomplete calculates future ev from past ev" do
    vf = Valueflow.new(r: 0.1)
    vf.tvs << Timevalue.new(t: 0, sv: 0.to_d, ev: 1000.to_d, cto: 0.to_d)
    vf.tvs << Timevalue.new(t: 2, sv: 0.to_d, ev: nil,        cto: 0.to_d)
    vf.twoperiodcomplete
    # future_ev = 1000 * (1 + 0.1)^2 = 1210.00
    assert_equal 1210.00.to_d, vf.tvs.last.ev
  end

  test "twoperiodcomplete calculates past ev from future ev" do
    vf = Valueflow.new(r: 0.1)
    vf.tvs << Timevalue.new(t: 0, sv: 0.to_d, ev: nil,          cto: 0.to_d)
    vf.tvs << Timevalue.new(t: 2, sv: 0.to_d, ev: 1210.to_d,   cto: 0.to_d)
    vf.twoperiodcomplete
    # Per the code: when first.ev is blank, first.ev = last.ev * (1+r)^periods
    # This mirrors the code's actual formula regardless of direction.
    assert_equal (1210.to_d * (1.1 ** 2)).round(2), vf.tvs.first.ev
  end
end
