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
  resources :service_types, except: :destroy do
    patch :activate, on: :member
    patch :deactivate, on: :member
  end
  resources :work_orders, except: :destroy do
    resource :assignment, only: :create
    resources :executions, only: %i[show create] do
      resources :evidences, only: :create do
        get :original, on: :member
      end
      resources :participants, controller: "execution_participants", only: %i[create destroy]
      post :arrive, to: "execution_events#arrive"
      post :start_work, to: "execution_events#start_work"
      post :pause, to: "execution_events#pause"
      post :resume, to: "execution_events#resume"
      post :finish_work, to: "execution_events#finish_work"
      post :unable, to: "execution_events#unable"
      post :leave, to: "execution_events#leave"
      post :submit, to: "execution_events#submit"
    end
  end

  resources :my_work, only: :index

  resources :customers, except: :destroy do
    resources :sites, except: %i[index destroy] do
      resources :assets, except: %i[index destroy]
    end
  end

  resource :organization_selection, only: %i[show update]
  resource :dashboard, only: %i[show]
end
