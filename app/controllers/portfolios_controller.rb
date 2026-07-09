class PortfoliosController < ApplicationController
  before_action :set_portfolio, only: %i[show edit update destroy]

  def index
    @portfolios = current_user.portfolios.order(:name)
  end

  def show
  end

  def new
    @portfolio = current_user.portfolios.build
  end

  def create
    @portfolio = current_user.portfolios.build(portfolio_params)

    if @portfolio.save
      redirect_to portfolios_path, notice: "Portefeuille créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @portfolio.update(portfolio_params)
      redirect_to portfolios_path, notice: "Portefeuille mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @portfolio.destroy
    redirect_to portfolios_path, notice: "Portefeuille supprimé.", status: :see_other
  end

  private

  def set_portfolio
    @portfolio = current_user.portfolios.find(params[:id])
  end

  def portfolio_params
    params.expect(portfolio: %i[name account_type opening_date])
  end
end
