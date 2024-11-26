Rails.application.routes.draw do
  resource :users, only: [:show, :update, :destroy] do
    post '/signup', to: 'users#create'
    post '/login', to: 'users#login'
  end

  resources :survey_forms, only: [:create, :show, :update, :destroy] do 
    resources :questions, only: [:create, :show, :update, :destroy]
  end
  resources :mcq_options, only: [:create, :show, :update, :destroy]
  # resources :answers, only: [:create, :show, :update]  
  resources :answers, only: [:index, :create, :show, :destroy] do
    collection do
      put '/', to: 'answers#update'
      get 'download_csv/:survey_form_id', to: 'answers#download_csv', as: 'download_csv'
    end
  end
end