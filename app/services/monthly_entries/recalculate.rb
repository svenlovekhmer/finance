module MonthlyEntries
  # Recomputes cumulative_contribution, cumulative_capital and delta for every
  # MonthlyEntry of a Position, in chronological order, starting from the
  # Position's initial_capital / initial_contribution baseline.
  #
  # Runs as a full recompute rather than resuming from a single changed month:
  # the series is small enough that this is simpler and avoids drift.
  class Recalculate
    def initialize(position)
      @position = position
    end

    def call
      previous_capital = position.initial_capital.to_f
      previous_contribution = position.initial_contribution.to_f

      position.monthly_entries.order(:month).each do |entry|
        contribution = entry.contribution_amount.to_f
        variation_pct = entry.applied_variation_pct.to_f

        cumulative_capital = previous_capital * (1 + variation_pct / 100.0) + contribution
        cumulative_contribution = previous_contribution + contribution
        delta = cumulative_capital - cumulative_contribution

        entry.update_columns(
          cumulative_capital: cumulative_capital,
          cumulative_contribution: cumulative_contribution,
          delta: delta
        )

        previous_capital = cumulative_capital
        previous_contribution = cumulative_contribution
      end
    end

    private

    attr_reader :position
  end
end
