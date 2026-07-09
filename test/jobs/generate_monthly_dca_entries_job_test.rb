require "test_helper"

class GenerateMonthlyDcaEntriesJobTest < ActiveSupport::TestCase
  def build_position(auto_dca:, data_source: "auto", ticker: "ESE.PA")
    user = User.create!(email: "dca#{SecureRandom.hex(4)}@example.com", password: "password123")
    portfolio = Portfolio.create!(user: user, name: "PEA", account_type: "PEA")
    Position.create!(
      portfolio: portfolio, asset_name: "BNP Paribas Easy S&P 500", benchmark_name: "S&P 500",
      asset_class: "actions",
      data_source: data_source, auto_dca: auto_dca, ticker: ticker
    )
  end

  def stub_yahoo_variation(ticker, from_close:, to_close:)
    stub_request(:get, "https://query1.finance.yahoo.com/v8/finance/chart/#{ticker}")
      .with(query: { interval: "1mo", range: "5y" })
      .to_return(
        status: 200,
        body: {
          chart: { result: [ {
            timestamp: [ Time.utc(2026, 1, 5).to_i, Time.utc(2026, 2, 4).to_i ],
            indicators: { quote: [ { close: [ from_close, to_close ] } ] }
          } ] }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  test "creates the month's entry for an auto_dca position with prior history" do
    position = build_position(auto_dca: true)
    position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 1, contribution_amount: 200, planned_contribution_amount: 200)
    stub_yahoo_variation("ESE.PA", from_close: 100.0, to_close: 105.0)

    assert_difference "position.monthly_entries.count", 1 do
      GenerateMonthlyDcaEntriesJob.new.perform(month: Date.new(2026, 2, 1))
    end

    entry = position.monthly_entries.order(:month).last
    assert_equal Date.new(2026, 2, 1), entry.month
    assert_in_delta 5.0, entry.benchmark_variation_pct.to_f
    assert_in_delta 200.0, entry.contribution_amount.to_f
    assert_in_delta 200.0, entry.planned_contribution_amount.to_f
  end

  test "ignores positions without auto_dca enabled" do
    position = build_position(auto_dca: false)
    position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 1, contribution_amount: 200, planned_contribution_amount: 200)

    assert_no_difference "position.monthly_entries.count" do
      GenerateMonthlyDcaEntriesJob.new.perform(month: Date.new(2026, 2, 1))
    end
  end

  test "skips a position with no prior entry to seed the recurring amount from" do
    build_position(auto_dca: true)

    assert_no_difference "MonthlyEntry.count" do
      GenerateMonthlyDcaEntriesJob.new.perform(month: Date.new(2026, 2, 1))
    end
  end

  test "skips a position when the Yahoo fetch fails, leaving it for manual entry" do
    position = build_position(auto_dca: true)
    position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 1, contribution_amount: 200, planned_contribution_amount: 200)
    stub_request(:get, "https://query1.finance.yahoo.com/v8/finance/chart/ESE.PA")
      .with(query: { interval: "1mo", range: "5y" })
      .to_return(status: 500)

    assert_no_difference "position.monthly_entries.count" do
      GenerateMonthlyDcaEntriesJob.new.perform(month: Date.new(2026, 2, 1))
    end
  end

  test "is idempotent when an entry already exists for the month" do
    position = build_position(auto_dca: true)
    position.monthly_entries.create!(month: Date.new(2026, 1, 1), benchmark_variation_pct: 1, contribution_amount: 200, planned_contribution_amount: 200)
    position.monthly_entries.create!(month: Date.new(2026, 2, 1), benchmark_variation_pct: 2, contribution_amount: 200, planned_contribution_amount: 200)

    assert_no_difference "position.monthly_entries.count" do
      GenerateMonthlyDcaEntriesJob.new.perform(month: Date.new(2026, 2, 1))
    end
  end
end
