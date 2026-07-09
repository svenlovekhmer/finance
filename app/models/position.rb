class Position < ApplicationRecord
  belongs_to :portfolio
  has_many :monthly_entries, -> { order(:month) }, dependent: :destroy

  validates :asset_name, presence: true
  validates :benchmark_name, presence: true
  validates :asset_class, presence: true
  validates :ter_pct, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :initial_capital, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :initial_contribution, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_save :recalculate_monthly_entries, if: :recalculation_needed?

  private

  def recalculation_needed?
    (saved_change_to_initial_capital? || saved_change_to_initial_contribution?) && monthly_entries.any?
  end

  def recalculate_monthly_entries
    MonthlyEntries::Recalculate.new(self).call
  end
end
