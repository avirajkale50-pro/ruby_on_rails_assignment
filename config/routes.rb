Rails.application.routes.draw do
  resources :blogs do
    member do
      patch :publish
    end
    resources :comments, only: [:create, :index, :destroy]
  end
end
