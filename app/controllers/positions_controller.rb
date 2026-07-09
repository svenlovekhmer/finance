class PositionsController < ApplicationController
  before_action :set_portfolio
  before_action :set_position, only: %i[show edit update destroy]

  def show
    @monthly_entries = @position.monthly_entries.order(:month)
  end

  def new
    @position = @portfolio.positions.build
  end

  def create
    @position = @portfolio.positions.build(position_params)

    if @position.save
      redirect_to portfolio_path(@portfolio), notice: "Position créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @position.update(position_params)
      redirect_to portfolio_path(@portfolio), notice: "Position mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @position.destroy
    redirect_to portfolio_path(@portfolio), notice: "Position supprimée.", status: :see_other
  end

  private

  def set_portfolio
    @portfolio = current_user.portfolios.find(params[:portfolio_id])
  end

  def set_position
    @position = @portfolio.positions.find(params[:id])
  end

  def position_params
    params.expect(position: %i[
      asset_name ticker benchmark_name asset_class ter_pct
      initial_capital initial_contribution
    ])
  end
end
