Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :contacts, only: [:new, :create]
  resources :visitors do
   collection do
     get :new_build
   end
  end
  root to: 'visitors#new'
end
