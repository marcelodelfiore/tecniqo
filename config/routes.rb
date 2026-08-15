Rails.application.routes.draw do
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check

  get "/login",  to: "sessions#new", as: :new_session
  post "/session", to: "sessions#create", as: :session
  get "/session/confirm", to: "sessions#show", as: :magic_session
  post "/session/confirm", to: "sessions#update", as: :consume_magic_session
  delete "/session", to: "sessions#destroy"
  patch "/locale", to: "locales#update", as: :locale

  get "/invitation", to: "invitations#show", as: :invitation_acceptance
  post "/invitation", to: "invitations#update", as: :consume_invitation

  resources :invitations, only: %i[index new create destroy] do
    post :resend, on: :member
  end
  resources :memberships, only: %i[index edit update]

  resources :customers, except: :destroy do
    resources :sites, except: %i[index destroy] do
      resources :assets, except: %i[index destroy]
    end
  end

  resource :organization_selection, only: %i[show update]
  resource :dashboard, only: %i[show]
end
