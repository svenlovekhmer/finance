module Positions
  # Time-weighted return: chains each month's applied variation regardless of
  # contribution size, so it reflects actual performance instead of being
  # skewed by when/how much was paid in (unlike the raw euro delta).
  class TimeWeightedReturn
    Result = Struct.new(:cumulative_pct, :annualized_pct, :months)

    # Annualizing a return computed from only a few months extrapolates
    # noise into something that looks precise — only report it once there's
    # at least a year of history.
    MIN_MONTHS_FOR_ANNUALIZED = 12

    def initialize(position)
      @position = position
    end

    def call
      entries = position.monthly_entries.order(:month).to_a
      return Result.new(nil, nil, 0) if entries.empty?

      growth_factor = entries.reduce(1.0) do |factor, entry|
        factor * (1 + entry.applied_variation_pct.to_f / 100.0)
      end

      months = entries.size
      annualized = growth_factor**(12.0 / months) - 1 if months >= MIN_MONTHS_FOR_ANNUALIZED

      Result.new((growth_factor - 1) * 100, annualized && annualized * 100, months)
    end

    private

    attr_reader :position
  end
end
