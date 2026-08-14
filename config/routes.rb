Rails.application.routes.draw do
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check

  get "/login",  to: "sessions#new", as: :new_session
  post "/session", to: "sessions#create", as: :session
  get "/session/confirm", to: "sessions#show", as: :magic_session
  post "/session/confirm", to: "sessions#update", as: :consume_magic_session
  delete "/session", to: "sessions#destroy"

  resource :dashboard, only: %i[show]
end
