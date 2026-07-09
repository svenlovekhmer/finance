require "test_helper"

module MarketData
  class YahooFinanceClientTest < ActiveSupport::TestCase
    test "search returns the quotes array" do
      stub_request(:get, "https://query1.finance.yahoo.com/v1/finance/search")
        .with(query: { q: "nasdaq" })
        .to_return(
          status: 200,
          body: { quotes: [ { symbol: "ESE.PA", shortname: "Amundi Nasdaq" } ] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      results = YahooFinanceClient.new.search("nasdaq")

      assert_equal 1, results.size
      assert_equal "ESE.PA", results.first["symbol"]
    end

    test "search returns an empty array when the response has no quotes" do
      stub_request(:get, "https://query1.finance.yahoo.com/v1/finance/search")
        .with(query: { q: "zzz" })
        .to_return(status: 200, body: {}.to_json, headers: { "Content-Type" => "application/json" })

      assert_equal [], YahooFinanceClient.new.search("zzz")
    end

    test "chart returns the first result node" do
      body = { chart: { result: [ { timestamp: [ 1 ], indicators: { quote: [ { close: [ 100.0 ] } ] } } ] } }
      stub_request(:get, "https://query1.finance.yahoo.com/v8/finance/chart/ESE.PA")
        .with(query: { interval: "1mo", range: "5y" })
        .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })

      result = YahooFinanceClient.new.chart("ESE.PA")

      assert_equal [ 1 ], result["timestamp"]
    end

    test "raises on a non-success HTTP response" do
      stub_request(:get, "https://query1.finance.yahoo.com/v1/finance/search")
        .with(query: { q: "x" })
        .to_return(status: 500)

      assert_raises(YahooFinanceClient::Error) { YahooFinanceClient.new.search("x") }
    end

    test "raises on malformed JSON" do
      stub_request(:get, "https://query1.finance.yahoo.com/v1/finance/search")
        .with(query: { q: "x" })
        .to_return(status: 200, body: "not json")

      assert_raises(YahooFinanceClient::Error) { YahooFinanceClient.new.search("x") }
    end

    test "raises when the chart response has no result node" do
      stub_request(:get, "https://query1.finance.yahoo.com/v8/finance/chart/BADTICKER")
        .with(query: { interval: "1mo", range: "5y" })
        .to_return(
          status: 200,
          body: { chart: { result: nil, error: { code: "Not Found" } } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      assert_raises(YahooFinanceClient::Error) { YahooFinanceClient.new.chart("BADTICKER") }
    end
  end
end
