Rails.application.routes.draw do
  devise_for :users
  resources :users, only: [:index, :show, :new, :create, :edit, :update]

  resources :blogs do
    collection do
      get :published
      get :unpublished
    end
    member do
      patch :publish
    end
    resources :comments, only: [:create, :index, :destroy]
  end
end
