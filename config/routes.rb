Rails.application.routes.draw do
  # Authentication
  get "auth/google_oauth2/callback", to: "sessions#create"
  post "auth/google_oauth2/callback", to: "sessions#create"
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

  # Prospects
  resources :prospects do
    member do
      patch :disqualify
      patch :convert
    end
  end

  # Proposals
  resources :proposals do
    member do
      patch :mark_won
      patch :mark_lost
      post :duplicate
      post :archive_document
    end
  end

  # Tasks
  resources :tasks do
    member do
      patch :mark_done
      patch :cancel
      patch :reassign
    end
  end

  # Customers
  resources :customers do
    resources :contacts, only: [ :new, :create, :edit, :update, :destroy ]
  end

  # Pipeline
  get "pipeline", to: "pipeline#index", as: :pipeline

  # Touchpoints
  resources :touchpoints, only: [ :create ]

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "dashboard#index"
end
