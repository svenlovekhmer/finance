class DashboardController < ApplicationController
  def show
    @summary = Dashboards::AggregateSummary.new(current_user)
    @drawdown = DrawdownCalculator.new(@summary.time_series.map { |point| [ point.month, point.capital ] }).call
  end
end
