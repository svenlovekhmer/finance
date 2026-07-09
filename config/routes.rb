Rails.application.routes.draw do
  devise_for :users

  get "dashboard", to: "dashboard#show"
  get "market_data/search", to: "market_data#search"

  resources :portfolios do
    resources :positions, except: [ :index ] do
      resources :monthly_entries, except: [ :index, :show ]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"
end
