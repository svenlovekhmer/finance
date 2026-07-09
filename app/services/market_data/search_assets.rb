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
        exchange: quote["exchDisp"] || quote["exchange"],
        suggested_asset_class: suggested_asset_class(quote["quoteType"])
      }
    end

    # A best-effort guess, not a fact — Yahoo's search endpoint doesn't
    # expose what a fund actually holds, so this only covers the case that's
    # unambiguous from the quote type alone (a single stock, or the very
    # common case of an equity-tracking ETF). Bond/commodity/mixed ETFs and
    # mutual funds are left blank rather than guessed wrong.
    def suggested_asset_class(quote_type)
      "actions" if %w[EQUITY ETF].include?(quote_type)
    end
  end
end
