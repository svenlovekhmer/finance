class MonthlyEntry < ApplicationRecord
  belongs_to :position

  validates :month, presence: true, uniqueness: { scope: :position_id }
  validate :month_is_first_of_month
  validates :benchmark_variation_pct, presence: true, numericality: true
  validates :actual_variation_pct, numericality: true, allow_nil: true
  validates :contribution_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :planned_contribution_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  after_save :recalculate_cascade, if: :recalculation_needed?

  # The applied variation follows an override rule: a manually entered actual
  # variation (e.g. to reflect tracking error or fees) always wins over the
  # benchmark's variation.
  def applied_variation_pct
    actual_variation_pct.presence || benchmark_variation_pct
  end

  private

  def month_is_first_of_month
    return if month.blank? || month.day == 1

    errors.add(:month, "doit être le 1er du mois")
  end

  def recalculation_needed?
    saved_change_to_month? ||
      saved_change_to_benchmark_variation_pct? ||
      saved_change_to_actual_variation_pct? ||
      saved_change_to_contribution_amount?
  end

  def recalculate_cascade
    MonthlyEntries::Recalculate.new(position).call
  end
end
