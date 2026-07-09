require "test_helper"

class PortfoliosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_users_portfolio = portfolios(:two)
  end

  test "redirects to sign in when not authenticated" do
    get portfolios_path

    assert_redirected_to new_user_session_path
  end

  test "index only lists the current user's portfolios" do
    sign_in @user

    get portfolios_path

    assert_response :success
    assert_match portfolios(:one).name, response.body
    assert_no_match @other_users_portfolio.name, response.body
  end

  test "create with valid attributes" do
    sign_in @user

    assert_difference "@user.portfolios.count", 1 do
      post portfolios_path, params: { portfolio: { name: "CTO", account_type: "CTO", opening_date: "2024-01-01" } }
    end

    assert_redirected_to portfolios_path
  end

  test "create with invalid attributes re-renders the form" do
    sign_in @user

    assert_no_difference "Portfolio.count" do
      post portfolios_path, params: { portfolio: { name: "", account_type: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "update changes the portfolio's attributes" do
    sign_in @user
    portfolio = portfolios(:one)

    patch portfolio_path(portfolio), params: { portfolio: { name: "PEA renommé" } }

    assert_redirected_to portfolios_path
    assert_equal "PEA renommé", portfolio.reload.name
  end

  test "cannot update another user's portfolio" do
    sign_in @user

    patch portfolio_path(@other_users_portfolio), params: { portfolio: { name: "Hacked" } }

    assert_response :not_found
  end

  test "destroy removes the portfolio" do
    sign_in @user
    portfolio = portfolios(:one)

    assert_difference "Portfolio.count", -1 do
      delete portfolio_path(portfolio)
    end

    assert_redirected_to portfolios_path
  end

  test "cannot destroy another user's portfolio" do
    sign_in @user

    delete portfolio_path(@other_users_portfolio)

    assert_response :not_found
  end
end
