require "net/http"

module MarketData
  # Thin wrapper around Yahoo Finance's undocumented, unofficial JSON
  # endpoints (the same ones the `yfinance` ecosystem relies on). There is no
  # official free API with Euronext Paris coverage, so every caller of this
  # client must be prepared for it to fail or change shape without notice —
  # see MarketData::MonthlyVariation for the expected fallback behavior.
  class YahooFinanceClient
    Error = Class.new(StandardError)

    BASE_URL = "https://query1.finance.yahoo.com"
    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

    def search(query)
      get("/v1/finance/search", q: query)["quotes"] || []
    end

    # Returns the raw "result[0]" node of the chart response: a hash with
    # "timestamp" (array of unix seconds) and
    # dig("indicators", "quote", 0, "close") (array of closing prices).
    def chart(ticker, interval: "1mo", range: "5y")
      response = get("/v8/finance/chart/#{ticker}", interval: interval, range: range)
      result = response.dig("chart", "result", 0)
      raise Error, "No chart data returned for #{ticker}" if result.nil?

      result
    end

    private

    def get(path, params)
      uri = URI.join(BASE_URL, path)
      uri.query = URI.encode_www_form(params)

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        http.request(request)
      end

      raise Error, "Yahoo Finance returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Error, "Invalid response from Yahoo Finance: #{e.message}"
    rescue Timeout::Error, SocketError, SystemCallError => e
      raise Error, "Could not reach Yahoo Finance: #{e.message}"
    end
  end
end
