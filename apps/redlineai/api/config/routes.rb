Rails.application.routes.draw do
  # User profile routes
  get '/profile', to: 'profiles#show'
  get '/profile/edit', to: 'profiles#edit'
  patch '/profile', to: 'profiles#update'
  put '/profile', to: 'profiles#update'
  delete '/profile/picture', to: 'profiles#remove_profile_picture', as: :remove_profile_picture


  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  get "costs/index"
  # Root path
  root "home#index"

  # Health check
  get '/healthz', to: 'health#show'

  # Job monitoring endpoint
  get '/admin/jobs', to: 'admin/jobs#index'

  # Cost tracking
  get '/costs', to: 'costs#index'

  # Subscription management
  resource :subscription, only: [:show] do
    collection do
      get :index
      patch :upgrade
      patch :cancel
      patch :reactivate
    end
  end

  # Analytics (admin only)
  get '/analytics', to: 'analytics#index'

  # Admin namespace
  namespace :admin do
    get '/', to: 'dashboard#index', as: :dashboard
    resources :users, only: [:index, :show]
    resources :billings, only: [:index]
    resources :costs, only: [:index]
  end

      # Document management
    resources :documents, only: [:index, :create, :show, :new, :destroy] do
    member do
      # AI analysis endpoints
      post :summarize, to: 'ai#summarize_and_risks', as: :summarize_ai
      post :answer, to: 'ai#answer_question', as: :answer_ai
      post :redlines, to: 'ai#propose_redlines', as: :redlines_ai
      get :ai_results, to: 'ai#show', as: :ai_results
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
