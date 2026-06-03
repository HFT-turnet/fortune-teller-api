require "test_helper"

class PlanitemTest < ActiveSupport::TestCase
  # --- enum ---

  test "category enum maps life_phase to 1" do
    pi = Planitem.new(category: :life_phase)
    assert_equal 1, Planitem.categories[:life_phase]
    assert pi.life_phase?
  end

  test "category enum maps change_in_life to 2" do
    pi = Planitem.new(category: :change_in_life)
    assert_equal 2, Planitem.categories[:change_in_life]
    assert pi.change_in_life?
  end

  test "category enum maps investment to 3" do
    pi = Planitem.new(category: :investment)
    assert_equal 3, Planitem.categories[:investment]
    assert pi.investment?
  end

  # --- category_text ---

  test "category_text returns 'Life Phase' for life_phase" do
    pi = Planitem.new(category: :life_phase)
    assert_equal "Life Phase", pi.category_text
  end

  test "category_text returns 'Change in Life' for change_in_life" do
    pi = Planitem.new(category: :change_in_life)
    assert_equal "Change in Life", pi.category_text
  end

  test "category_text returns 'Investment' for investment" do
    pi = Planitem.new(category: :investment)
    assert_equal "Investment", pi.category_text
  end

  test "category_text returns nil when category is nil" do
    pi = Planitem.new(category: nil)
    assert_nil pi.category_text
  end

  # --- associations ---

  test "planitem belongs to a case" do
    pi = planitems(:one)
    assert_instance_of Case, pi.case
  end

  test "planitem has many cslices" do
    pi = planitems(:one)
    assert_respond_to pi, :cslices
  end

  test "planitem has many cvalues" do
    pi = planitems(:one)
    assert_respond_to pi, :cvalues
  end

  # --- date fields (requires DB) ---

  test "fromt, tot, leadt, trailt are stored and retrieved as Date objects" do
    c = Case.create!(byear: 1980, dyear: 2080, sex: 1)
    pi = c.planitems.create!(
      title: "Test Phase",
      category: :life_phase,
      fromt:  Date.new(2024, 1, 1),
      tot:    Date.new(2067, 1, 1),
      leadt:  Date.new(2022, 6, 1),
      trailt: Date.new(2070, 6, 1)
    )
    pi.reload
    assert_instance_of Date, pi.fromt
    assert_instance_of Date, pi.tot
    assert_instance_of Date, pi.leadt
    assert_instance_of Date, pi.trailt
    assert_equal Date.new(2024, 1, 1), pi.fromt
    assert_equal Date.new(2067, 1, 1), pi.tot
    assert_equal Date.new(2022, 6, 1), pi.leadt
    assert_equal Date.new(2070, 6, 1), pi.trailt
    c.delete_all
  end

  test "planitem is valid with all required attributes" do
    c = Case.create!(byear: 1980, dyear: 2080, sex: 1)
    pi = c.planitems.create!(
      title: "Investment Phase",
      category: :investment,
      fromt:  Date.new(2030, 1, 1),
      tot:    Date.new(2080, 1, 1)
    )
    assert pi.persisted?
    c.delete_all
  end

  test "cslices are nullified when planitem is destroyed" do
    c = Case.create!(byear: 1980, dyear: 2080, sex: 1)
    pi = c.planitems.create!(title: "Phase", category: :phase)
    csl = c.cslices.create!(cvaluetype: 1, label: "Income", t: 2025, planitem_id: pi.id)
    pi.destroy
    csl.reload
    assert_nil csl.planitem_id
    c.delete_all
  end

  # --- adjust_related_on_time_change callback ---

  test "updating planitem fromt/tot adjusts direct cvalue with differing fromt and tot" do
    c = Case.create!(byear: 2000, dyear: 2080, sex: 1)
    pi = c.planitems.create!(title: "Work", category: :phase, fromt: 2025, tot: 2060)
    cv = c.cvalues.create!(
      planitem_id: pi.id,
      cvaluetype: 1,
      label: "Salary",
      cto: 1000.to_d,
      ev: 0.to_d,
      fromt: 2025,
      tot: 2060,
      t: 2025,
      inflation: 0.to_d,
      interest: 0.to_d
    )
    pi.update!(fromt: 2026, tot: 2065)
    cv.reload
    assert_equal 2026, cv.fromt
    assert_equal 2065, cv.tot
    assert_equal 2025, cv.t
    c.delete_all
  end

  test "updating planitem fromt/tot sets both fromt and tot to new fromt when original fromt equals tot" do
    c = Case.create!(byear: 2000, dyear: 2080, sex: 1)
    pi = c.planitems.create!(title: "Pit", category: :pit, fromt: 2030, tot: 2030)
    cv = c.cvalues.create!(
      planitem_id: pi.id,
      cvaluetype: 2,
      label: "Expense",
      cto: 500.to_d,
      ev: 0.to_d,
      fromt: 2030,
      tot: 2030,
      t: 2030,
      inflation: 0.to_d,
      interest: 0.to_d
    )
    pi.update!(fromt: 2035, tot: 2050)
    cv.reload
    assert_equal 2035, cv.fromt
    assert_equal 2035, cv.tot
    c.delete_all
  end

  test "updating planitem fromt/tot adjusts cvalue belonging to a linked cslice" do
    c = Case.create!(byear: 2000, dyear: 2080, sex: 1)
    pi = c.planitems.create!(title: "Work", category: :phase, fromt: 2025, tot: 2060)
    csl = c.cslices.create!(cvaluetype: 2, label: "Housing", t: 2025, planitem_id: pi.id)
    cv = csl.cvalues.create!(
      case_id: c.id,
      cvaluetype: 2,
      label: "Rent",
      cto: 1200.to_d,
      ev: 0.to_d,
      fromt: 2025,
      tot: 2060,
      t: 2025,
      inflation: 0.to_d,
      interest: 0.to_d
    )
    pi.update!(fromt: 2027, tot: 2065)
    cv.reload
    assert_equal 2027, cv.fromt
    assert_equal 2065, cv.tot
    assert_equal 2025, cv.t
    c.delete_all
  end

  test "updating planitem fromt/tot re-simulates linked cslice" do
    c = Case.create!(byear: 2000, dyear: 2080, sex: 1)
    pi = c.planitems.create!(title: "Work", category: :phase, fromt: 2025, tot: 2026)
    csl = c.cslices.create!(cvaluetype: 1, label: "Income", t: 2025, planitem_id: pi.id)
    csl.cvalues.create!(
      case_id: c.id,
      cvaluetype: 1,
      label: "Salary",
      cto: 1000.to_d,
      ev: 0.to_d,
      fromt: 2025,
      tot: 2026,
      t: 2025,
      inflation: 0.to_d,
      interest: 0.to_d
    )
    pi.update!(fromt: 2027, tot: 2028)
    sim_count = c.simulations.where(sourcetype: 2, sourceid: csl.id).count
    assert sim_count > 0
    c.delete_all
  end

  test "updating planitem title only does not trigger time change callback" do
    c = Case.create!(byear: 2000, dyear: 2080, sex: 1)
    pi = c.planitems.create!(title: "Work", category: :phase, fromt: 2025, tot: 2060)
    cv = c.cvalues.create!(
      planitem_id: pi.id,
      cvaluetype: 1,
      label: "Salary",
      cto: 1000.to_d,
      ev: 0.to_d,
      fromt: 2025,
      tot: 2060,
      t: 2025,
      inflation: 0.to_d,
      interest: 0.to_d
    )
    pi.update!(title: "New Title")
    cv.reload
    assert_equal 2025, cv.fromt
    assert_equal 2060, cv.tot
    c.delete_all
  end
end
