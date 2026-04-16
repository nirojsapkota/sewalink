Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  devise_scope :user do
    get 'users/otp', to: 'users/sessions#otp', as: :users_otp
    post 'users/verify_otp', to: 'users/sessions#verify_otp', as: :verify_otp
  end

  resource :onboarding, only: [:show, :update], controller: 'onboarding'
  resource :profile, only: [:show, :edit, :update], controller: 'profiles' do
    patch :toggle_role
  end

  resources :tasks do
    resources :bids, only: [:create] do
      member do
        patch :accept
      end
    end
  end

  resources :bids, only: [:update, :destroy]

  root "home#index"
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
