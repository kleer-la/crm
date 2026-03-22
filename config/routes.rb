Rails.application.routes.draw do
  # Authentication
  get "auth/google_oauth2/callback", to: "sessions#create"
  get "auth/failure", to: "sessions#failure"
  delete "logout", to: "sessions#destroy", as: :logout
  get "login", to: "sessions#new", as: :login
  get "pending", to: "sessions#pending", as: :pending_approval

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "dashboard#index"
end
