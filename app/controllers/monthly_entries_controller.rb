class MonthlyEntriesController < ApplicationController
  before_action :set_position
  before_action :set_monthly_entry, only: %i[edit update destroy]

  def new
    last_entry = @position.monthly_entries.order(:month).last

    @monthly_entry = @position.monthly_entries.build(
      month: last_entry ? last_entry.month.next_month : Date.current.beginning_of_month,
      planned_contribution_amount: last_entry&.planned_contribution_amount,
      contribution_amount: last_entry&.planned_contribution_amount
    )
  end

  def create
    @monthly_entry = @position.monthly_entries.build(monthly_entry_params)

    if @monthly_entry.save
      redirect_to portfolio_position_path(@portfolio, @position), notice: "Entrée mensuelle ajoutée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @monthly_entry.update(monthly_entry_params)
      redirect_to portfolio_position_path(@portfolio, @position), notice: "Entrée mensuelle mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @monthly_entry.destroy
    redirect_to portfolio_position_path(@portfolio, @position), notice: "Entrée mensuelle supprimée.", status: :see_other
  end

  private

  def set_position
    @portfolio = current_user.portfolios.find(params[:portfolio_id])
    @position = @portfolio.positions.find(params[:position_id])
  end

  def set_monthly_entry
    @monthly_entry = @position.monthly_entries.find(params[:id])
  end

  def monthly_entry_params
    attributes = params.expect(monthly_entry: %i[
      month benchmark_variation_pct actual_variation_pct
      contribution_amount planned_contribution_amount notes
    ])

    # The month input is an HTML <input type="month">, which submits
    # "YYYY-MM" (no day) — append the day so the :date column casts it.
    if attributes[:month].present? && attributes[:month].match?(/\A\d{4}-\d{2}\z/)
      attributes[:month] = "#{attributes[:month]}-01"
    end

    attributes
  end
end
