# Computes the worst peak-to-trough decline in a capital time series (a
# standard "max drawdown" figure). Shared between a single Position's own
# capital history and the user's aggregated dashboard series, both of which
# are simple [month, capital] pairs.
class DrawdownCalculator
  Result = Struct.new(:max_drawdown_pct, :peak_month, :trough_month)

  def initialize(series)
    @series = series
  end

  def call
    peak = nil
    peak_month = nil
    worst_pct = 0.0
    worst_peak_month = nil
    worst_trough_month = nil

    series.each do |month, capital|
      capital = capital.to_f

      if peak.nil? || capital > peak
        peak = capital
        peak_month = month
      end

      next if peak.blank? || peak <= 0

      drawdown_pct = (capital - peak) / peak * 100
      if drawdown_pct < worst_pct
        worst_pct = drawdown_pct
        worst_peak_month = peak_month
        worst_trough_month = month
      end
    end

    Result.new(worst_pct, worst_peak_month, worst_trough_month)
  end

  private

  attr_reader :series
end
