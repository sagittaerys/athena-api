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
    end
  end
end

# mann gotta love rails man...
