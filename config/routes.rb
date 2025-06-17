Rails.application.routes.draw do
  root to: "accounts#index"

  resources :accounts, only: :index do
    resources :contacts, only: :index

    namespace :contacts do
      resources :imports, except: :index
    end
  end
end
