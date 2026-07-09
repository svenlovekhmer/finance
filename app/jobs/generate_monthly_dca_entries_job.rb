# Runs daily (see config/recurring.yml) rather than only on the 1st, so a
# failed fetch or network hiccup gets retried automatically over the following
# days instead of silently leaving the month unattended until someone notices.
class GenerateMonthlyDcaEntriesJob < ApplicationJob
  queue_as :default

  def perform(month: Date.current.beginning_of_month)
    Position.where(auto_dca: true).find_each do |position|
      generate_entry_for(position, month)
    end
  end

  private

  def generate_entry_for(position, month)
    return if position.monthly_entries.exists?(month: month)

    last_entry = position.monthly_entries.order(:month).last
    return if last_entry.nil? # nothing to seed the recurring amount from yet

    variation = MarketData::MonthlyVariation.new.call(position.ticker, month)
    return if variation.nil? # can't create a valid entry without one — try again next run

    position.monthly_entries.create!(
      month: month,
      benchmark_variation_pct: variation,
      planned_contribution_amount: last_entry.planned_contribution_amount,
      contribution_amount: last_entry.planned_contribution_amount
    )
  end
end
