require "test_helper"

module Dashboards
  class AggregateSummaryTest < ActiveSupport::TestCase
    def build_portfolio(user)
      Portfolio.create!(user: user, name: "PEA", account_type: "PEA")
    end

    def build_position(portfolio, name)
      Position.create!(
        portfolio: portfolio, asset_name: name, benchmark_name: "Nasdaq 100",
        asset_class: "actions", initial_capital: 0, initial_contribution: 0
      )
    end

    test "reports zero totals and no entries when the user has nothing tracked" do
      user = User.create!(email: "empty@example.com", password: "password123")
      summary = AggregateSummary.new(user)

      assert_not summary.any_entries?
      assert_equal 0, summary.total_capital
      assert_equal 0, summary.total_contribution
      assert_equal 0, summary.total_delta
      assert_equal [], summary.time_series
    end

    test "aggregates a single position's totals and time series" do
      user = User.create!(email: "single@example.com", password: "password123")
      position = build_position(build_portfolio(user), "Amundi Nasdaq-100")
      position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5, contribution_amount: 100, planned_contribution_amount: 100)
      position.monthly_entries.create!(month: Date.new(2026, 2, 1), benchmark_variation_pct: 10, contribution_amount: 100, planned_contribution_amount: 100)

      summary = AggregateSummary.new(user)

      assert summary.any_entries?
      assert_in_delta 210.00, summary.total_capital
      assert_in_delta 200.00, summary.total_contribution
      assert_in_delta 10.00, summary.total_delta

      jan, feb = summary.time_series
      assert_equal Date.new(2026, 1, 1), jan.month
      assert_in_delta 100.00, jan.capital
      assert_in_delta 210.00, feb.capital
      assert_in_delta 10.00, feb.delta
    end

    test "carries forward each position's last known value for months it has no entry" do
      user = User.create!(email: "multi@example.com", password: "password123")
      portfolio = build_portfolio(user)
      position_a = build_position(portfolio, "Position A")
      position_b = build_position(portfolio, "Position B")

      position_a.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5, contribution_amount: 100, planned_contribution_amount: 100)
      position_a.monthly_entries.create!(month: Date.new(2026, 2, 1), benchmark_variation_pct: 10, contribution_amount: 100, planned_contribution_amount: 100)
      # Position B only starts being tracked in February.
      position_b.monthly_entries.create!(month: Date.new(2026, 2, 1), benchmark_variation_pct: 0, contribution_amount: 50, planned_contribution_amount: 50)

      summary = AggregateSummary.new(user)

      assert_in_delta 260.00, summary.total_capital # 210 + 50
      assert_in_delta 250.00, summary.total_contribution # 200 + 50

      jan, feb = summary.time_series
      # January: only position A has an entry at or before this month.
      assert_in_delta 100.00, jan.capital
      assert_in_delta 100.00, jan.contribution
      # February: both positions contribute.
      assert_in_delta 260.00, feb.capital
      assert_in_delta 250.00, feb.contribution
    end

    test "ignores other users' portfolios" do
      user = User.create!(email: "scoped@example.com", password: "password123")
      other_user = User.create!(email: "other@example.com", password: "password123")
      other_position = build_position(build_portfolio(other_user), "Not mine")
      other_position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 5, contribution_amount: 100, planned_contribution_amount: 100)

      summary = AggregateSummary.new(user)

      assert_not summary.any_entries?
      assert_equal 0, summary.total_capital
    end
  end
end
