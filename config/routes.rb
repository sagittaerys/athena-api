Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :register
        post :login
        post :refresh
        delete :logout
      end

      resources :books, only: [ :index, :show ] do
        collection do
          get :genres
        end
      end

      resources :library_items, only: [ :index, :show, :create, :destroy ] do
        member do
          post :parse_epub
        end
      end

      resources :library_items, only: [ :index, :show, :create, :destroy ]

      resources :voice_profiles, only: [ :show, :create, :destroy ]
    end
  end
end

# mann gotta love rails man...
