Rails.application.routes.draw do
  get 'tasker_dashboard', to: 'tasker_dashboard#index', as: :tasker_dashboard
  resource :poster_dashboard, only: [:show], module: :posters, controller: :dashboards
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  devise_scope :user do
    get 'users/otp', to: 'users/sessions#otp', as: :users_otp
    post 'users/verify_otp', to: 'users/sessions#verify_otp', as: :verify_otp
    post 'users/resend_otp', to: 'users/sessions#resend_otp', as: :resend_otp
  end

  resource :onboarding, only: [:show, :update], controller: 'onboarding'
  resource :profile, only: [:show, :edit, :update], controller: 'profiles' do
    patch :toggle_role
  end

  resources :conversations, only: [:show] do
    resources :messages, only: [:create]
  end

  resources :tasks do
    member do
      post :request_payment
      post :release_payment
      post :raise_dispute
      patch :toggle_draft
      post :check_geofence # New route for geolocation checks
      post :perform_check_in # New route for manual check-in
      patch :complete     # New route for marking task as complete
      delete :delete_photo
    end
    resource :completion, only: [:create], module: :tasks
    resource :start, only: [:create], module: :tasks
    resources :bids, only: [:create] do
      member do
        patch :accept
      end
    end
    resources :reviews, only: [:create]
    resources :dispute_evidences, only: [:create]
  end

  resources :payments, only: [:create] do
    collection do
      get :success
      get :failure
    end
  end

  resources :bids, only: [:update, :destroy]
  resource :live_chat, only: [:show]

  namespace :tasker do
    resource :wallet, only: [:show]
    resources :payout_requests, only: [:create]
  end

  namespace :admin do
    root to: 'dashboards#show'
    get '/', to: 'dashboards#show' # Extra alias for clarity if needed, but root to: is enough
    resources :users, only: [:index, :show]
    resources :payouts, only: [:index] do
      member do
        patch :process_payout
        patch :reject_payout
      end
    end
    resources :tasks, only: [:index, :show]
    resources :disputes, only: [:index, :show] do
      member do
        patch :resolve
      end
    end
  end

  namespace :api do
    resources :voice_tasks, only: [:create] do
      collection do
        delete :reset
      end
    end
    resources :assistant, only: [:create]
  end

  namespace :gemini do
    resources :tokens, only: [:create]
    post 'tools/execute', to: 'tools#execute'
  end

  root "home#index"
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
