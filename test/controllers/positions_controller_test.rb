require "test_helper"

class PositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @portfolio = portfolios(:one)
    @position = positions(:one)
    @other_users_portfolio = portfolios(:two)
  end

  test "redirects to sign in when not authenticated" do
    get portfolio_position_path(@portfolio, @position)

    assert_redirected_to new_user_session_path
  end

  test "show renders the position" do
    sign_in @user

    get portfolio_position_path(@portfolio, @position)

    assert_response :success
    assert_match @position.asset_name, response.body
  end

  test "create with valid attributes" do
    sign_in @user

    assert_difference "@portfolio.positions.count", 1 do
      post portfolio_positions_path(@portfolio), params: { position: {
        asset_name: "Amundi MSCI World",
        benchmark_name: "MSCI World",
        asset_class: "actions",
        ter_pct: "0.38"
      } }
    end

    assert_redirected_to portfolio_path(@portfolio)
  end

  test "create with invalid attributes re-renders the form" do
    sign_in @user

    assert_no_difference "Position.count" do
      post portfolio_positions_path(@portfolio), params: { position: { asset_name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "update changes the position's attributes" do
    sign_in @user

    patch portfolio_position_path(@portfolio, @position), params: { position: { asset_name: "Renommé" } }

    assert_redirected_to portfolio_path(@portfolio)
    assert_equal "Renommé", @position.reload.asset_name
  end

  test "destroy removes the position" do
    sign_in @user

    assert_difference "Position.count", -1 do
      delete portfolio_position_path(@portfolio, @position)
    end

    assert_redirected_to portfolio_path(@portfolio)
  end

  test "cannot access positions of another user's portfolio" do
    sign_in @user

    get portfolio_position_path(@other_users_portfolio, positions(:two))

    assert_response :not_found
  end

  test "cannot create a position under another user's portfolio" do
    sign_in @user

    post portfolio_positions_path(@other_users_portfolio), params: { position: {
      asset_name: "Intrus", benchmark_name: "S&P 500", asset_class: "actions"
    } }

    assert_response :not_found
  end
end
