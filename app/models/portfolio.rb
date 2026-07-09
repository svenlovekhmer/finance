class Portfolio < ApplicationRecord
  ACCOUNT_TYPES = %w[PEA CTO assurance-vie autre].freeze

  belongs_to :user
  has_many :positions, dependent: :destroy

  validates :name, presence: true
  validates :account_type, presence: true, inclusion: { in: ACCOUNT_TYPES }
end
