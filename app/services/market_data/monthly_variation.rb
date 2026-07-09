module MarketData
  # Looks up a ticker's percentage change for a given calendar month from
  # Yahoo Finance's monthly chart data. Returns nil — never raises — on
  # anything going wrong (network error, unknown ticker, missing month),
  # so callers can always fall back to asking the user to fill it in by hand.
  class MonthlyVariation
    def initialize(client: YahooFinanceClient.new)
      @client = client
    end

    def call(ticker, month)
      return nil if ticker.blank?

      closes_by_month = monthly_closes(ticker)
      current_close = closes_by_month[month.beginning_of_month]
      previous_close = closes_by_month[month.beginning_of_month.prev_month]

      return nil if current_close.nil? || previous_close.nil? || previous_close.zero?

      ((current_close - previous_close) / previous_close) * 100
    rescue YahooFinanceClient::Error
      nil
    end

    private

    attr_reader :client

    def monthly_closes(ticker)
      result = client.chart(ticker, interval: "1mo")
      timestamps = result["timestamp"] || []
      closes = result.dig("indicators", "quote", 0, "close") || []

      timestamps.zip(closes).filter_map do |timestamp, close|
        next if close.nil?

        [ Time.at(timestamp).utc.to_date.beginning_of_month, close.to_f ]
      end.to_h
    end
  end
end
