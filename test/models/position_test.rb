require "test_helper"

class PositionTest < ActiveSupport::TestCase
  def valid_attributes
    {
      portfolio: portfolios(:one),
      asset_name: "Amundi Nasdaq-100",
      benchmark_name: "Nasdaq 100",
      asset_class: "actions",
      initial_capital: 0,
      initial_contribution: 0
    }
  end

  test "valid with required attributes" do
    assert Position.new(valid_attributes).valid?
  end

  test "invalid without an asset_name" do
    position = Position.new(valid_attributes.merge(asset_name: nil))

    assert_not position.valid?
  end

  test "invalid without a benchmark_name" do
    position = Position.new(valid_attributes.merge(benchmark_name: nil))

    assert_not position.valid?
  end

  test "invalid without an asset_class" do
    position = Position.new(valid_attributes.merge(asset_class: nil))

    assert_not position.valid?
  end

  test "invalid with a negative ter_pct" do
    position = Position.new(valid_attributes.merge(ter_pct: -0.1))

    assert_not position.valid?
  end

  test "valid without a ter_pct" do
    position = Position.new(valid_attributes.merge(ter_pct: nil))

    assert position.valid?
  end

  test "destroying a position destroys its monthly entries" do
    assert_difference "MonthlyEntry.count", -1 do
      positions(:one).destroy
    end
  end
end
