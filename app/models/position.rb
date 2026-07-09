class Position < ApplicationRecord
  DATA_SOURCES = %w[manual auto].freeze

  belongs_to :portfolio
  has_many :monthly_entries, -> { order(:month) }, dependent: :destroy

  validates :asset_name, presence: true
  validates :ter_pct, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :data_source, presence: true, inclusion: { in: DATA_SOURCES }
  validate :auto_dca_requires_automatic_data_source

  def auto?
    data_source == "auto"
  end

  private

  def auto_dca_requires_automatic_data_source
    return unless auto_dca? && !auto?

    errors.add(:auto_dca, "nécessite une source de données automatique (ticker suivi via Yahoo Finance)")
  end
end
