require "test_helper"

class SimulationTest < ActiveSupport::TestCase
  # valuetype_text (instance method): returns a human-readable label for the valuetype
  test "valuetype_text returns Income for valuetype 1" do
    sim = Simulation.new(valuetype: 1)
    assert_equal "Income", sim.valuetype_text
  end

  test "valuetype_text returns Expense for valuetype 2" do
    sim = Simulation.new(valuetype: 2)
    assert_equal "Expense", sim.valuetype_text
  end

  test "valuetype_text returns Cash_Balance_Move for valuetype 3" do
    sim = Simulation.new(valuetype: 3)
    assert_equal "Cash_Balance_Move", sim.valuetype_text
  end

  test "valuetype_text returns Automatic Savings Balance for valuetype 10" do
    sim = Simulation.new(valuetype: 10)
    assert_equal "Automatic Savings Balance", sim.valuetype_text
  end

  test "valuetype_text returns Savings Balance (Cash) for valuetype 11" do
    sim = Simulation.new(valuetype: 11)
    assert_equal "Savings Balance (Cash)", sim.valuetype_text
  end

  test "valuetype_text returns Debt Balance (Cash) for valuetype 12" do
    sim = Simulation.new(valuetype: 12)
    assert_equal "Debt Balance (Cash)", sim.valuetype_text
  end

  # valuetype_text (class method): same mapping via the class-level method
  test "Simulation.valuetype_text returns Income for 1" do
    assert_equal "Income", Simulation.valuetype_text(1)
  end

  test "Simulation.valuetype_text returns Expense for 2" do
    assert_equal "Expense", Simulation.valuetype_text(2)
  end

  test "Simulation.valuetype_text returns nil for unknown valuetype" do
    assert_nil Simulation.valuetype_text(99)
  end

  # sourcetype_text: returns a human-readable label for the sourcetype
  test "sourcetype_text returns Internal automatism for sourcetype 0" do
    sim = Simulation.new(sourcetype: 0)
    assert_equal "Internal automatism", sim.sourcetype_text
  end

  test "sourcetype_text returns Cvalue for sourcetype 1" do
    sim = Simulation.new(sourcetype: 1)
    assert_equal "Cvalue", sim.sourcetype_text
  end

  test "sourcetype_text returns Cslice for sourcetype 2" do
    sim = Simulation.new(sourcetype: 2)
    assert_equal "Cslice", sim.sourcetype_text
  end

  test "sourcetype_text returns Cflow for sourcetype 3" do
    sim = Simulation.new(sourcetype: 3)
    assert_equal "Cflow", sim.sourcetype_text
  end

  test "sourcetype_text returns CPensionflow for sourcetype 4" do
    sim = Simulation.new(sourcetype: 4)
    assert_equal "CPensionflow", sim.sourcetype_text
  end

  test "sourcetype_text returns nil for an unknown sourcetype" do
    sim = Simulation.new(sourcetype: 99)
    assert_nil sim.sourcetype_text
  end
end
