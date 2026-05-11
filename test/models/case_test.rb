require "test_helper"

class CaseTest < ActiveSupport::TestCase
  # sex_text: returns a string representation of the sex field
  test "sex_text returns male for sex 1" do
    c = Case.new(sex: 1)
    assert_equal "male", c.sex_text
  end

  test "sex_text returns female for sex 2" do
    c = Case.new(sex: 2)
    assert_equal "female", c.sex_text
  end

  test "sex_text returns diverse for sex 3" do
    c = Case.new(sex: 3)
    assert_equal "diverse", c.sex_text
  end

  test "sex_text returns nil for an unknown sex value" do
    c = Case.new(sex: 99)
    assert_nil c.sex_text
  end

  # before_save callbacks (require DB)

  test "external_id is generated on create" do
    c = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    assert c.external_id.present?
    assert_match(/\A[0-9a-f-]{36}\z/, c.external_id)
    c.destroy
  end

  test "nodelete defaults to false when not set" do
    c = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    assert_equal false, c.nodelete
    c.destroy
  end

  test "nodelete is preserved when explicitly set to true" do
    c = Case.create!(byear: 1980, dyear: 2050, sex: 1, nodelete: true)
    assert_equal true, c.nodelete
    c.destroy
  end

  # timeline: returns aggregated simulation data grouped by year and valuetype
  test "timeline returns a hash" do
    c = cases(:one)
    # No simulations attached in fixture so timeline should return empty or hash
    # When no simulations exist, the result will be {}
    result = c.timeline(5)
    assert result.is_a?(Hash)
  end

  # details: returns detailed simulation entries for a given year
  test "details returns a hash" do
    c = cases(:one)
    result = c.details(2025)
    assert result.is_a?(Hash)
  end

  test "simulate_pensionpoints creates cumulative point balances" do
    c = Case.create!(byear: 2020, dyear: 2030, sex: 1)
    c.simulations.create!(valuetype: 15, sourcetype: 1, sourceid: 1, t: 2025, value: 1.2)
    c.simulations.create!(valuetype: 15, sourcetype: 2, sourceid: 1, t: 2025, value: 0.8)
    c.simulations.create!(valuetype: 15, sourcetype: 1, sourceid: 2, t: 2026, value: 1.0)

    c.simulate_pensionpoints

    y2025 = c.simulations.find_by(valuetype: 16, sourcetype: 0, t: 2025)
    y2026 = c.simulations.find_by(valuetype: 16, sourcetype: 0, t: 2026)
    assert_equal 2.0.to_d, y2025.value.to_d
    assert_equal 3.0.to_d, y2026.value.to_d
    c.delete_all
  end

  # delete_all: destroys case and associated records
  test "delete_all destroys the case" do
    c = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    case_id = c.id
    c.delete_all
    assert_nil Case.find_by(id: case_id)
  end
end
