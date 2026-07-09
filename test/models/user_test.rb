require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has many portfolios" do
    assert_respond_to users(:one), :portfolios
  end

  test "destroying a user destroys its portfolios" do
    user = users(:one)

    assert_difference "Portfolio.count", -1 do
      user.destroy
    end
  end
end
