class MarketDataController < ApplicationController
  def search
    render json: MarketData::SearchAssets.new.call(params[:q])
  end
end
