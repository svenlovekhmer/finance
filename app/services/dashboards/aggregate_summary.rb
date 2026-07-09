module Dashboards
  # Aggregates every position across every portfolio of a user into the
  # totals and combined time series shown on the dashboard.
  #
  # Positions can start tracking in different months, so the time series is
  # built by carrying forward each position's last known entry at or before
  # a given month rather than assuming all positions share the same months.
  class AggregateSummary
    Point = Struct.new(:month, :capital, :contribution, :delta)

    def initialize(user)
      @user = user
    end

    def total_capital
      latest_entries.sum { |entry| entry.cumulative_capital.to_f }
    end

    def total_contribution
      latest_entries.sum { |entry| entry.cumulative_contribution.to_f }
    end

    def total_delta
      total_capital - total_contribution
    end

    def any_entries?
      entries_by_position.values.any?(&:present?)
    end

    def time_series
      months.map do |month|
        capital = 0.0
        contribution = 0.0

        entries_by_position.each_value do |entries|
          entry = entries.select { |e| e.month <= month }.max_by(&:month)
          next unless entry

          capital += entry.cumulative_capital.to_f
          contribution += entry.cumulative_contribution.to_f
        end

        Point.new(month, capital, contribution, capital - contribution)
      end
    end

    private

    attr_reader :user

    def months
      entries_by_position.values.flatten.map(&:month).uniq.sort
    end

    def latest_entries
      entries_by_position.values.filter_map(&:last)
    end

    def entries_by_position
      @entries_by_position ||= positions.to_h do |position|
        [ position.id, position.monthly_entries.order(:month).to_a ]
      end
    end

    def positions
      @positions ||= Position.where(portfolio: user.portfolios)
    end
  end
end
