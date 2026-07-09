require "test_helper"

module MarketData
  class SearchAssetsTest < ActiveSupport::TestCase
    FakeClient = Struct.new(:quotes) do
      def search(_query)
        quotes
      end
    end

    test "returns an empty array for a blank query" do
      assert_equal [], SearchAssets.new(client: FakeClient.new([])).call("")
      assert_equal [], SearchAssets.new(client: FakeClient.new([])).call(nil)
    end

    test "keeps only ETF, equity and mutual fund quote types" do
      quotes = [
        { "symbol" => "ESE.PA", "longname" => "BNP Paribas Easy S&P 500", "exchDisp" => "Paris", "quoteType" => "ETF" },
        { "symbol" => "AAPL", "longname" => "Apple Inc.", "exchDisp" => "NASDAQ", "quoteType" => "EQUITY" },
        { "symbol" => "NQ=F", "shortname" => "Nasdaq 100 Futures", "quoteType" => "FUTURE" },
        { "symbol" => "^NDX", "longname" => "NASDAQ-100", "quoteType" => "INDEX" }
      ]

      results = SearchAssets.new(client: FakeClient.new(quotes)).call("nasdaq")

      assert_equal [ "ESE.PA", "AAPL" ], results.pluck(:ticker)
    end

    test "formats each result with name, ticker and exchange" do
      quotes = [ { "symbol" => "ESE.PA", "longname" => "BNP Paribas Easy S&P 500", "exchDisp" => "Paris", "quoteType" => "ETF" } ]

      result = SearchAssets.new(client: FakeClient.new(quotes)).call("sp500").first

      assert_equal({ ticker: "ESE.PA", name: "BNP Paribas Easy S&P 500", exchange: "Paris" }, result)
    end

    test "falls back to shortname when longname is missing" do
      quotes = [ { "symbol" => "ESE.PA", "shortname" => "BNP Easy SP500", "quoteType" => "ETF" } ]

      result = SearchAssets.new(client: FakeClient.new(quotes)).call("sp500").first

      assert_equal "BNP Easy SP500", result[:name]
    end

    test "returns an empty array instead of raising when the client errors out" do
      failing_client = Object.new
      def failing_client.search(*)
        raise MarketData::YahooFinanceClient::Error, "boom"
      end

      assert_equal [], SearchAssets.new(client: failing_client).call("x")
    end
  end
end
