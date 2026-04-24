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

  # delete_all: destroys case and associated records
  test "delete_all destroys the case" do
    c = Case.create!(byear: 1980, dyear: 2050, sex: 1)
    case_id = c.id
    c.delete_all
    assert_nil Case.find_by(id: case_id)
  end
end
