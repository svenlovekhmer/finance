require "test_helper"

class MarketDataControllerTest < ActionDispatch::IntegrationTest
  test "redirects to sign in when not authenticated" do
    get market_data_search_path(q: "nasdaq")

    assert_redirected_to new_user_session_path
  end

  test "returns matching ETFs and equities as JSON" do
    sign_in users(:one)

    stub_request(:get, "https://query1.finance.yahoo.com/v1/finance/search")
      .with(query: { q: "nasdaq" })
      .to_return(
        status: 200,
        body: {
          quotes: [
            { symbol: "ESE.PA", longname: "BNP Paribas Easy S&P 500", exchDisp: "Paris", quoteType: "ETF" },
            { symbol: "NQ=F", shortname: "Nasdaq 100 Futures", quoteType: "FUTURE" }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get market_data_search_path(q: "nasdaq")

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal "ESE.PA", body.first["ticker"]
  end

  test "returns an empty array when the query is blank" do
    sign_in users(:one)

    get market_data_search_path(q: "")

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end
end
