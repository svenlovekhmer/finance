require "test_helper"

class DrawdownCalculatorTest < ActiveSupport::TestCase
  test "returns zero drawdown for an empty series" do
    result = DrawdownCalculator.new([]).call

    assert_equal 0.0, result.max_drawdown_pct
    assert_nil result.peak_month
    assert_nil result.trough_month
  end

  test "returns zero drawdown for a single point" do
    result = DrawdownCalculator.new([ [ Date.new(2026, 1, 1), 100 ] ]).call

    assert_equal 0.0, result.max_drawdown_pct
  end

  test "returns zero drawdown when the series only rises" do
    series = [ [ Date.new(2026, 1, 1), 100 ], [ Date.new(2026, 2, 1), 150 ], [ Date.new(2026, 3, 1), 200 ] ]

    result = DrawdownCalculator.new(series).call

    assert_equal 0.0, result.max_drawdown_pct
  end

  test "picks the worst drawdown among several, not the first" do
    series = [
      [ Date.new(2026, 1, 1), 100 ],
      [ Date.new(2026, 2, 1), 150 ], # peak
      [ Date.new(2026, 3, 1), 90 ],  # -40% from peak
      [ Date.new(2026, 4, 1), 120 ], # recovering, -20% from peak
      [ Date.new(2026, 5, 1), 60 ],  # new worst, -60% from the same peak
      [ Date.new(2026, 6, 1), 200 ]  # new peak, drawdown resets to 0
    ]

    result = DrawdownCalculator.new(series).call

    assert_in_delta(-60.0, result.max_drawdown_pct)
    assert_equal Date.new(2026, 2, 1), result.peak_month
    assert_equal Date.new(2026, 5, 1), result.trough_month
  end

  test "does not divide by zero when capital starts at zero" do
    series = [ [ Date.new(2026, 1, 1), 0 ], [ Date.new(2026, 2, 1), 100 ], [ Date.new(2026, 3, 1), 50 ] ]

    result = DrawdownCalculator.new(series).call

    assert_in_delta(-50.0, result.max_drawdown_pct)
  end
end
