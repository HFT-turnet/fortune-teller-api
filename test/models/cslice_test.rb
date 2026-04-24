require "test_helper"

class CsliceTest < ActiveSupport::TestCase
  # cvaluetype_text: returns the label for the cvaluetype integer
  test "cvaluetype_text returns Income for type 1" do
    csl = Cslice.new(cvaluetype: 1)
    assert_equal "Income", csl.cvaluetype_text
  end

  test "cvaluetype_text returns Expense for type 2" do
    csl = Cslice.new(cvaluetype: 2)
    assert_equal "Expense", csl.cvaluetype_text
  end

  test "cvaluetype_text returns Cashbalance for type 3" do
    csl = Cslice.new(cvaluetype: 3)
    assert_equal "Cashbalance", csl.cvaluetype_text
  end

  test "cvaluetype_text returns nil for an unknown type" do
    csl = Cslice.new(cvaluetype: 99)
    assert_nil csl.cvaluetype_text
  end

  # sync_cvalues: propagates case dates and slice t to all attached cvalues (requires DB)
  test "sync_cvalues sets t on each cvalue from the cslice" do
    c = Case.create!(byear: 2000, dyear: 2050, sex: 1)
    csl = c.cslices.create!(cvaluetype: 2, label: "Housing", t: 2025)
    cv = csl.cvalues.create!(
      case_id: c.id,
      cvaluetype: 2,
      label: "Rent",
      cto: 1000.to_d,
      ev: 0.to_d,
      fromt: 2000,
      tot: 2050,
      inflation: 0.to_d,
      interest: 0.to_d
    )
    csl.sync_cvalues
    cv.reload
    assert_equal 2025, cv.t
    assert_equal 2000, cv.fromt
    assert_equal 2050, cv.tot
    c.delete_all
  end

  # simulate: creates Simulation records for each year in the case's lifespan (requires DB)
  test "simulate creates simulation records for the case lifespan" do
    c = Case.create!(byear: 2025, dyear: 2026, sex: 1)
    csl = c.cslices.create!(cvaluetype: 2, label: "Rent", t: 2025)
    csl.cvalues.create!(
      case_id: c.id,
      cvaluetype: 2,
      label: "Rent",
      cto: 1200.to_d,
      ev: 0.to_d,
      fromt: 2025,
      tot: 2026,
      inflation: 0.to_d,
      interest: 0.to_d
    )
    csl.simulate
    sim_count = c.simulations.where(sourcetype: 2, sourceid: csl.id).count
    assert sim_count > 0
    c.delete_all
  end
end
