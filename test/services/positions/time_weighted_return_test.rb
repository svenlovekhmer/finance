require "test_helper"

module Positions
  class TimeWeightedReturnTest < ActiveSupport::TestCase
    def build_position
      user = User.create!(email: "twr#{SecureRandom.hex(4)}@example.com", password: "password123")
      portfolio = Portfolio.create!(user: user, name: "PEA", account_type: "PEA")
      Position.create!(
        portfolio: portfolio, asset_name: "Amundi Nasdaq-100", benchmark_name: "Nasdaq 100",
        asset_class: "actions"
      )
    end

    test "returns nil figures when the position has no entries" do
      result = TimeWeightedReturn.new(build_position).call

      assert_nil result.cumulative_pct
      assert_nil result.annualized_pct
      assert_equal 0, result.months
    end

    test "chains monthly variations regardless of contribution size" do
      position = build_position
      position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5, contribution_amount: 1000, planned_contribution_amount: 1000)
      position.monthly_entries.create!(month: Date.new(2026, 2, 1), benchmark_variation_pct: 10, contribution_amount: 10, planned_contribution_amount: 10)
      position.monthly_entries.create!(month: Date.new(2026, 3, 1), benchmark_variation_pct: -2, contribution_amount: 0, planned_contribution_amount: 0)

      result = TimeWeightedReturn.new(position).call

      # 1.05 * 1.10 * 0.98 = 1.1319 -> +13.19%, independent of contribution amounts
      assert_in_delta 13.19, result.cumulative_pct, 0.01
      assert_equal 3, result.months
      assert_nil result.annualized_pct # fewer than 12 months of history
    end

    test "actual_variation_pct overrides benchmark_variation_pct in the chain" do
      position = build_position
      position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5, actual_variation_pct: 0, contribution_amount: 100, planned_contribution_amount: 100)

      result = TimeWeightedReturn.new(position).call

      assert_in_delta 0.0, result.cumulative_pct
    end

    test "annualizes once there are at least 12 months of history" do
      position = build_position
      24.times do |i|
        position.monthly_entries.create!(
          month: Date.new(2026, 1, 1) + i.months, benchmark_variation_pct: 1,
          contribution_amount: 100, planned_contribution_amount: 100
        )
      end

      result = TimeWeightedReturn.new(position).call

      expected_cumulative = ((1.01**24) - 1) * 100
      expected_annualized = ((1.01**24)**(12.0 / 24) - 1) * 100

      assert_in_delta expected_cumulative, result.cumulative_pct, 0.01
      assert_in_delta expected_annualized, result.annualized_pct, 0.01
    end
  end
end
