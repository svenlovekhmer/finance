class DashboardController < ApplicationController
  def show
    @summary = Dashboards::AggregateSummary.new(current_user)
  end
end
