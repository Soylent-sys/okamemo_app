Rails.application.routes.draw do
  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    registrations: 'users/registrations',
    passwords:     'users/passwords',
    sessions:      'users/sessions'
  }
  root 'home#index'
end
