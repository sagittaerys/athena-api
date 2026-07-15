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

      get "auth/me", to: "auth#me"

      resources :books, only: [ :index, :show ] do
        collection do
          get :genres
        end
      end

      resources :library_items, only: [ :index, :show, :create, :destroy ] do
        member do
          post :parse_epub
        end
        resources :audio_chunks, only: [ :create, :show ] do
          member do
            get :stream
          end
        end
      end

      resources :voice_profiles, only: [ :create, :show, :destroy ] do
        collection do
          get :current
        end
      end
    end
  end
end
