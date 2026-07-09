require "test_helper"

class PortfolioTest < ActiveSupport::TestCase
  test "valid with a name and an allowed account_type" do
    portfolio = Portfolio.new(user: users(:one), name: "PEA", account_type: "PEA")

    assert portfolio.valid?
  end

  test "invalid without a name" do
    portfolio = Portfolio.new(user: users(:one), account_type: "PEA")

    assert_not portfolio.valid?
    assert_includes portfolio.errors[:name], "can't be blank"
  end

  test "invalid with an account_type outside the allowed list" do
    portfolio = Portfolio.new(user: users(:one), name: "PEA", account_type: "livret A")

    assert_not portfolio.valid?
    assert_includes portfolio.errors[:account_type], "is not included in the list"
  end

  test "destroying a portfolio destroys its positions" do
    assert_difference "Position.count", -1 do
      portfolios(:one).destroy
    end
  end
end
