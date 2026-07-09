require "test_helper"

class MonthlyEntryTest < ActiveSupport::TestCase
  def valid_attributes
    {
      position: positions(:one),
      month: Date.new(2026, 3, 1),
      benchmark_variation_pct: 5.0,
      planned_contribution_amount: 100
    }
  end

  test "valid with required attributes" do
    assert MonthlyEntry.new(valid_attributes).valid?
  end

  test "invalid without a month" do
    entry = MonthlyEntry.new(valid_attributes.merge(month: nil))

    assert_not entry.valid?
  end

  test "invalid when month is not the first of the month" do
    entry = MonthlyEntry.new(valid_attributes.merge(month: Date.new(2026, 3, 15)))

    assert_not entry.valid?
    assert_includes entry.errors[:month], "doit être le 1er du mois"
  end

  test "invalid with a duplicate month for the same position" do
    MonthlyEntry.create!(valid_attributes)
    duplicate = MonthlyEntry.new(valid_attributes)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:month], "est déjà utilisé(e)"
  end

  test "invalid without a benchmark_variation_pct" do
    entry = MonthlyEntry.new(valid_attributes.merge(benchmark_variation_pct: nil))

    assert_not entry.valid?
  end

  test "invalid with a negative contribution_amount" do
    entry = MonthlyEntry.new(valid_attributes.merge(contribution_amount: -10))

    assert_not entry.valid?
  end

  test "valid with a nil contribution_amount (planned but not yet paid)" do
    entry = MonthlyEntry.new(valid_attributes.merge(contribution_amount: nil))

    assert entry.valid?
  end

  test "applied_variation_pct falls back to benchmark_variation_pct when actual is absent" do
    entry = MonthlyEntry.new(valid_attributes.merge(benchmark_variation_pct: 5.0, actual_variation_pct: nil))

    assert_equal 5.0, entry.applied_variation_pct
  end

  test "applied_variation_pct is overridden by actual_variation_pct, including zero" do
    entry = MonthlyEntry.new(valid_attributes.merge(benchmark_variation_pct: 5.0, actual_variation_pct: 0))

    assert_equal 0.to_d, entry.applied_variation_pct
  end

  test "saving an entry triggers a cascade recalculation on its position" do
    position = positions(:one)
    position.monthly_entries.destroy_all

    entry = MonthlyEntry.create!(
      position: position,
      month: Date.new(2026, 1, 1),
      benchmark_variation_pct: 5.0,
      contribution_amount: 100,
      planned_contribution_amount: 100
    )

    assert_equal 100.0, entry.reload.cumulative_capital.to_f
    assert_equal 100.0, entry.cumulative_contribution.to_f
    assert_equal 0.0, entry.delta.to_f
  end
end
