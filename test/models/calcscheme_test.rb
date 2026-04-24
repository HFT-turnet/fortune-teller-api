require "test_helper"

class CalcschemeTest < ActiveSupport::TestCase
  # load: reads a scheme JSON file and prepares the Calcscheme
  test "load returns OK for a valid countrycode and schemetype" do
    cs = Calcscheme.new
    result = cs.load("DE", "tax")
    assert_equal "OK", result
  end

  test "load sets country title and comment1 from file" do
    cs = Calcscheme.new
    cs.load("DE", "tax")
    assert_equal "Deutschland", cs.country
    assert_equal "Tax Calculation", cs.title
  end

  test "load populates schemes_versions" do
    cs = Calcscheme.new
    cs.load("DE", "tax")
    assert cs.schemes_versions.any?
  end

  test "load returns error message for non-existent schemetype" do
    cs = Calcscheme.new
    result = cs.load("DE", "nonexistent_scheme")
    assert_match /Error/, result
  end

  test "load returns error message for non-existent countrycode" do
    cs = Calcscheme.new
    result = cs.load("XX", "tax")
    assert_match /Error/, result
  end

  # set: selects a scheme and version within the loaded scheme
  test "set returns OK for a valid scheme and version" do
    cs = Calcscheme.new
    cs.load("DE", "tax")
    # "estTarif_2024" should be a known scheme_version
    result = cs.set("estTarif", "2024")
    assert_equal "OK", result
  end

  test "set returns error when scheme does not exist" do
    cs = Calcscheme.new
    cs.load("DE", "tax")
    result = cs.set("nonexistent", "2024")
    assert_match /Error/, result
  end

  test "set returns error when called before load" do
    cs = Calcscheme.new
    result = cs.set("estTarif", "2024")
    assert_match /Error/, result
  end

  test "set corrects to most recent version when version is absent" do
    cs = Calcscheme.new
    cs.load("DE", "tax")
    result = cs.set("estTarif", "0000")
    assert_match /Corrected/, result
  end

  # run: applies the scheme to a set of input values
  test "run returns OK with valid inputs" do
    cs = Calcscheme.new
    cs.load("DE", "tax")
    cs.set("estTarif", "2024")
    result = cs.run({ "zv_einkommen" => 50000 }, nil)
    assert_equal "OK", result
  end

  test "run populates result hash after a successful run" do
    cs = Calcscheme.new
    cs.load("DE", "tax")
    cs.set("estTarif", "2024")
    cs.run({ "zv_einkommen" => 50000 }, nil)
    assert cs.result.is_a?(Hash)
    assert cs.result.any?
  end

  test "run returns error when called before load and set" do
    cs = Calcscheme.new
    result = cs.run({ "zv_einkommen" => 50000 }, nil)
    assert_match /Error/, result
  end

  test "run returns error when inputs are not a hash" do
    cs = Calcscheme.new
    cs.load("DE", "tax")
    cs.set("estTarif", "2024")
    result = cs.run("not a hash", nil)
    assert_match /Error/, result
  end

  # listall: scans the jsonlib for scheme files and returns a summary hash
  test "listall returns a hash of schemes for a valid countrycode" do
    cs = Calcscheme.new
    result = cs.listall("DE")
    assert result.is_a?(Hash)
    assert result.any?
  end

  test "listall returns empty hash for unknown countrycode" do
    cs = Calcscheme.new
    result = cs.listall("ZZ")
    assert result.is_a?(Hash)
    assert_empty result
  end
end
