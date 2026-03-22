Rails.application.routes.draw do
  # Authentication
  get "auth/google_oauth2/callback", to: "sessions#create"
  get "auth/failure", to: "sessions#failure"
  delete "logout", to: "sessions#destroy", as: :logout
  get "login", to: "sessions#new", as: :login
  get "pending", to: "sessions#pending", as: :pending_approval

  # Admin
  namespace :admin do
    resources :users, only: [ :index ] do
      member do
        patch :assign_role
        patch :deactivate
        patch :reactivate
      end
    end
  end

  # Touchpoints
  resources :touchpoints, only: [ :create ]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "dashboard#index"
end
