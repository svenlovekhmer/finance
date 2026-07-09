require "test_helper"

module MonthlyEntries
  class RecalculateTest < ActiveSupport::TestCase
    def build_position
      Position.create!(
        portfolio: portfolios(:one),
        asset_name: "Amundi Nasdaq-100",
        benchmark_name: "Nasdaq 100",
        asset_class: "actions"
      )
    end

    test "cascades capital and contribution across consecutive months" do
      position = build_position

      position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5.0, contribution_amount: 100, planned_contribution_amount: 100)
      position.monthly_entries.create!(month: Date.new(2026, 2, 1), benchmark_variation_pct: 10.0, contribution_amount: 100, planned_contribution_amount: 100)
      position.monthly_entries.create!(month: Date.new(2026, 3, 1), benchmark_variation_pct: -5.0, actual_variation_pct: -2.0, contribution_amount: 100, planned_contribution_amount: 100)

      jan, feb, mar = position.monthly_entries.order(:month).to_a.map(&:reload)

      assert_in_delta 100.00, jan.cumulative_capital.to_f
      assert_in_delta 100.00, jan.cumulative_contribution.to_f
      assert_in_delta 0.00, jan.delta.to_f

      assert_in_delta 210.00, feb.cumulative_capital.to_f
      assert_in_delta 200.00, feb.cumulative_contribution.to_f
      assert_in_delta 10.00, feb.delta.to_f

      # actual_variation_pct (-2.0) overrides benchmark_variation_pct (-5.0)
      assert_in_delta 305.80, mar.cumulative_capital.to_f
      assert_in_delta 300.00, mar.cumulative_contribution.to_f
      assert_in_delta 5.80, mar.delta.to_f
    end

    test "capital already held before tracking started is entered as the first month's contribution" do
      position = build_position

      entry = position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 2.0, contribution_amount: 1000, planned_contribution_amount: 1000)

      # Like any other contribution, it doesn't earn that same month's growth.
      assert_in_delta 1000.00, entry.reload.cumulative_capital.to_f
      assert_in_delta 1000.00, entry.cumulative_contribution.to_f
      assert_in_delta 0.00, entry.delta.to_f
    end

    test "treats a nil contribution_amount as zero without erroring" do
      position = build_position

      entry = position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5.0, contribution_amount: nil, planned_contribution_amount: 100)

      assert_in_delta 0.00, entry.reload.cumulative_capital.to_f
      assert_in_delta 0.00, entry.cumulative_contribution.to_f
      assert_in_delta 0.00, entry.delta.to_f
    end

    test "editing a past entry recalculates every following month" do
      position = build_position

      position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5.0, contribution_amount: 100, planned_contribution_amount: 100)
      feb = position.monthly_entries.create!(month: Date.new(2026, 2, 1), benchmark_variation_pct: 10.0, contribution_amount: 100, planned_contribution_amount: 100)
      mar = position.monthly_entries.create!(month: Date.new(2026, 3, 1), benchmark_variation_pct: -5.0, actual_variation_pct: -2.0, contribution_amount: 100, planned_contribution_amount: 100)

      feb.update!(contribution_amount: 150)

      jan = position.monthly_entries.order(:month).first.reload

      # January is untouched: it comes before the edited month
      assert_in_delta 100.00, jan.cumulative_capital.to_f

      assert_in_delta 260.00, feb.reload.cumulative_capital.to_f
      assert_in_delta 250.00, feb.cumulative_contribution.to_f
      assert_in_delta 10.00, feb.delta.to_f

      assert_in_delta 354.80, mar.reload.cumulative_capital.to_f
      assert_in_delta 350.00, mar.cumulative_contribution.to_f
      assert_in_delta 4.80, mar.delta.to_f
    end

    test "is idempotent when run multiple times" do
      position = build_position
      position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5.0, contribution_amount: 100, planned_contribution_amount: 100)

      Recalculate.new(position).call
      first_run = position.monthly_entries.first.reload.cumulative_capital

      Recalculate.new(position).call
      second_run = position.monthly_entries.first.reload.cumulative_capital

      assert_equal first_run, second_run
    end

    test "does not run model validations when writing computed columns" do
      position = build_position
      entry = position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5.0, contribution_amount: 100, planned_contribution_amount: 100)

      # Corrupt a model-only validated field (not a DB constraint) directly in
      # the DB; a validation-triggering save would now fail with -10 < 0.
      entry.update_column(:contribution_amount, -10)

      assert_nothing_raised do
        Recalculate.new(position).call
      end
    end
  end
end
