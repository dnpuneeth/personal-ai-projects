Rails.application.routes.draw do
  get "costs/index"
  # Root path
  root "home#index"

  # Health check
  get '/healthz', to: 'health#show'

  # Costs tracking
  get '/costs', to: 'costs#index'

      # Document management
    resources :documents, only: [:index, :create, :show, :new, :destroy] do
    member do
      # AI analysis endpoints
      post :summarize, to: 'ai#summarize_and_risks', as: :summarize_ai
      post :answer, to: 'ai#answer_question', as: :answer_ai
      post :redlines, to: 'ai#propose_redlines', as: :redlines_ai
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
