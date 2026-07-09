module MarketData
  # Search-as-you-type lookup for the Position form's asset autocomplete.
  # Yahoo's search endpoint mixes in futures, indices, options, currencies —
  # keep only the instrument types someone would actually hold in a DCA plan.
  class SearchAssets
    RELEVANT_QUOTE_TYPES = %w[ETF EQUITY MUTUALFUND].freeze

    def initialize(client: YahooFinanceClient.new)
      @client = client
    end

    def call(query)
      return [] if query.blank?

      client.search(query)
        .select { |quote| RELEVANT_QUOTE_TYPES.include?(quote["quoteType"]) }
        .map { |quote| format_quote(quote) }
    rescue YahooFinanceClient::Error
      []
    end

    private

    attr_reader :client

    def format_quote(quote)
      {
        ticker: quote["symbol"],
        name: quote["longname"] || quote["shortname"],
        exchange: quote["exchDisp"] || quote["exchange"]
      }
    end
  end
end
