require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when not authenticated" do
    get root_path

    assert_redirected_to new_user_session_path
  end

  test "shows aggregated totals for a user with tracked positions" do
    sign_in users(:one)

    get root_path

    assert_response :success
    assert_select ".stat-tile", count: 3
  end

  test "shows an empty state for a user with no portfolios" do
    user = User.create!(email: "fresh@example.com", password: "password123")
    sign_in user

    get root_path

    assert_response :success
    assert_select ".stat-tile", count: 0
    assert_match "Aucune donnée", response.body
  end
end
