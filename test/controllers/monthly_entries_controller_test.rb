require "test_helper"

class MonthlyEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @portfolio = portfolios(:one)
    @position = positions(:one)
    @entry = monthly_entries(:one) # 2026-01-01, contribution 200, cumulative_capital 200
  end

  test "redirects to sign in when not authenticated" do
    get new_portfolio_position_monthly_entry_path(@portfolio, @position)

    assert_redirected_to new_user_session_path
  end

  test "new prefills the next month and last planned contribution" do
    sign_in @user

    get new_portfolio_position_monthly_entry_path(@portfolio, @position)

    assert_response :success
    assert_select "input#monthly_entry_month[value=?]", "2026-02"
    assert_select "input#monthly_entry_planned_contribution_amount[value=?]", "200.0"
  end

  test "create with valid attributes cascades from the previous month" do
    sign_in @user

    assert_difference "@position.monthly_entries.count", 1 do
      post portfolio_position_monthly_entries_path(@portfolio, @position), params: { monthly_entry: {
        month: "2026-02-01",
        benchmark_variation_pct: "10",
        contribution_amount: "100",
        planned_contribution_amount: "100"
      } }
    end

    assert_redirected_to portfolio_position_path(@portfolio, @position)
    new_entry = @position.monthly_entries.order(:month).last
    # 200 * 1.10 + 100 = 320
    assert_in_delta 320.00, new_entry.cumulative_capital.to_f
    assert_in_delta 300.00, new_entry.cumulative_contribution.to_f
    assert_in_delta 20.00, new_entry.delta.to_f
  end

  test "create with invalid attributes re-renders the form" do
    sign_in @user

    assert_no_difference "MonthlyEntry.count" do
      post portfolio_position_monthly_entries_path(@portfolio, @position), params: { monthly_entry: { month: "2026-02-01" } }
    end

    assert_response :unprocessable_entity
  end

  test "update cascades the change to later months" do
    sign_in @user
    later = @position.monthly_entries.create!(
      month: Date.new(2026, 2, 1), benchmark_variation_pct: 10,
      contribution_amount: 100, planned_contribution_amount: 100
    )

    patch portfolio_position_monthly_entry_path(@portfolio, @position, @entry), params: { monthly_entry: { contribution_amount: "250" } }

    assert_redirected_to portfolio_position_path(@portfolio, @position)
    # January: 250 cumulative_capital / cumulative_contribution, delta 0
    assert_in_delta 250.00, @entry.reload.cumulative_capital.to_f
    # February: 250 * 1.10 + 100 = 375
    assert_in_delta 375.00, later.reload.cumulative_capital.to_f
  end

  test "destroy cascades the remaining months from the position baseline" do
    sign_in @user
    later = @position.monthly_entries.create!(
      month: Date.new(2026, 2, 1), benchmark_variation_pct: 10,
      contribution_amount: 100, planned_contribution_amount: 100
    )

    assert_difference "MonthlyEntry.count", -1 do
      delete portfolio_position_monthly_entry_path(@portfolio, @position, @entry)
    end

    assert_redirected_to portfolio_position_path(@portfolio, @position)
    # With January gone, February now starts from the position's zero baseline: 0 * 1.10 + 100 = 100
    assert_in_delta 100.00, later.reload.cumulative_capital.to_f
  end

  test "cannot view the new entry form for another user's position" do
    sign_in @user

    get new_portfolio_position_monthly_entry_path(portfolios(:two), positions(:two))

    assert_response :not_found
  end

  test "cannot update a monthly entry on another user's position" do
    sign_in @user

    patch portfolio_position_monthly_entry_path(portfolios(:two), positions(:two), monthly_entries(:two)),
      params: { monthly_entry: { contribution_amount: "1" } }

    assert_response :not_found
  end
end
