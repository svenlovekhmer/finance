require "test_helper"

module MarketData
  class MonthlyVariationTest < ActiveSupport::TestCase
    FakeClient = Struct.new(:chart_result) do
      def chart(_ticker, interval: "1mo", range: "5y")
        chart_result
      end
    end

    test "computes the percentage change between two consecutive months" do
      chart_result = {
        "timestamp" => [ Time.utc(2026, 1, 5).to_i, Time.utc(2026, 2, 4).to_i ],
        "indicators" => { "quote" => [ { "close" => [ 100.0, 105.0 ] } ] }
      }

      result = MonthlyVariation.new(client: FakeClient.new(chart_result)).call("ESE.PA", Date.new(2026, 2, 1))

      assert_in_delta 5.0, result
    end

    test "returns nil when the previous month is missing from the series" do
      chart_result = {
        "timestamp" => [ Time.utc(2026, 2, 4).to_i ],
        "indicators" => { "quote" => [ { "close" => [ 105.0 ] } ] }
      }

      result = MonthlyVariation.new(client: FakeClient.new(chart_result)).call("ESE.PA", Date.new(2026, 2, 1))

      assert_nil result
    end

    test "skips null closes in the series without erroring" do
      chart_result = {
        "timestamp" => [ Time.utc(2026, 1, 5).to_i, Time.utc(2026, 2, 4).to_i ],
        "indicators" => { "quote" => [ { "close" => [ nil, 105.0 ] } ] }
      }

      result = MonthlyVariation.new(client: FakeClient.new(chart_result)).call("ESE.PA", Date.new(2026, 2, 1))

      assert_nil result
    end

    test "returns nil when the ticker is blank" do
      variation = MonthlyVariation.new(client: FakeClient.new({}))

      assert_nil variation.call("", Date.new(2026, 2, 1))
      assert_nil variation.call(nil, Date.new(2026, 2, 1))
    end

    test "returns nil instead of raising when the client errors out" do
      failing_client = Object.new
      def failing_client.chart(*args, **kwargs)
        raise MarketData::YahooFinanceClient::Error, "boom"
      end

      result = MonthlyVariation.new(client: failing_client).call("ESE.PA", Date.new(2026, 2, 1))

      assert_nil result
    end
  end
end
