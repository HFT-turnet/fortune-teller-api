require "test_helper"

class PurgeOldCasesJobTest < ActiveSupport::TestCase
  # Helper: create a case and back-date its updated_at (and that of related records).
  def create_case_last_accessed(days_ago:, nodelete: false)
    c = Case.create!(byear: 1980, dyear: 2060, sex: 1, nodelete: nodelete)
    timestamp = days_ago.days.ago
    Case.where(id: c.id).update_all(updated_at: timestamp)
    c
  end

  # --- Normal retention (90 days, nodelete: false) ---

  test "deletes a normal case whose last access is older than 90 days" do
    c = create_case_last_accessed(days_ago: 91)
    PurgeOldCasesJob.perform_now
    assert_nil Case.find_by(id: c.id), "Case should have been deleted"
  end

  test "keeps a normal case whose last access is within 90 days" do
    c = create_case_last_accessed(days_ago: 89)
    PurgeOldCasesJob.perform_now
    assert Case.exists?(c.id), "Case should still exist"
    c.delete_all
  end

  test "keeps a normal case that was accessed via a recent simulation" do
    c = create_case_last_accessed(days_ago: 91)
    # A simulation updated recently counts as a recent access.
    sim = c.simulations.create!(valuetype: 1, sourcetype: 0, t: 2030, value: 1000)
    Simulation.where(id: sim.id).update_all(updated_at: 1.day.ago)
    PurgeOldCasesJob.perform_now
    assert Case.exists?(c.id), "Case should still exist due to recent simulation"
    c.delete_all
  end

  test "keeps a normal case that was accessed via a recent cslice" do
    c = create_case_last_accessed(days_ago: 91)
    csl = c.cslices.create!(cvaluetype: 1, label: "Test", t: 2030)
    Cslice.where(id: csl.id).update_all(updated_at: 1.day.ago)
    PurgeOldCasesJob.perform_now
    assert Case.exists?(c.id), "Case should still exist due to recent cslice"
    c.delete_all
  end

  test "keeps a normal case that was accessed via a recent cvalue" do
    c = create_case_last_accessed(days_ago: 91)
    cv = c.cvalues.create!(cvaluetype: 1, label: "Salary", cto: 50000, fromt: 2000, tot: 2060, inflation: 0, interest: 0, ev: 0)
    Cvalue.where(id: cv.id).update_all(updated_at: 1.day.ago)
    PurgeOldCasesJob.perform_now
    assert Case.exists?(c.id), "Case should still exist due to recent cvalue"
    c.delete_all
  end

  # --- nodelete retention (3 years) ---

  test "keeps a nodelete case older than 90 days but within 3 years" do
    c = create_case_last_accessed(days_ago: 200, nodelete: true)
    PurgeOldCasesJob.perform_now
    assert Case.exists?(c.id), "nodelete case within 3 years should not be deleted"
    c.delete_all
  end

  test "deletes a nodelete case whose last access is older than 3 years" do
    c = create_case_last_accessed(days_ago: 3 * 366, nodelete: true)
    PurgeOldCasesJob.perform_now
    assert_nil Case.find_by(id: c.id), "nodelete case older than 3 years should be deleted"
  end

  # --- constants ---

  test "NORMAL_RETENTION is 90 days" do
    assert_equal 90.days, PurgeOldCasesJob::NORMAL_RETENTION
  end

  test "NODELETE_RETENTION is 3 years" do
    assert_equal 3.years, PurgeOldCasesJob::NODELETE_RETENTION
  end
end
