Rails.application.routes.draw do
  devise_for :users,
  controllers: {
    confirmations: 'users/confirmations',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    sessions: 'users/sessions',
  },
  path_names: {
    sign_in: 'log_in',
    sign_out: 'log_out',
    edit: 'edit/profile',
  }
  root 'home#index'
  get 'shopping/new', to: 'shopping_records#new'
  post 'shopping/new/back', to: 'shopping_records#back_new'
  post 'shopping/new/confirm', to: 'shopping_records#confirm'
  get 'shopping/index', to: 'shopping_records#index'
  get 'shopping/:id/progress', to: 'shopping_records#edit', as: 'shopping_progress'
  post 'shopping/progress/back', to: 'shopping_records#back_edit'
  post 'shopping/progress/confirm', to: 'shopping_records#edit_confirm'
  get 'shopping/result', to: 'shopping_records#result'
  get 'shopping/result/:id/show', to: 'shopping_records#show', as: 'shopping_results'
  get 'shopping/result/:id/location/new', to: 'shopping_locations#new', as: 'new_shopping_location'
  resources :shopping_records, only: [:create, :update, :destroy]
  resources :shopping_locations, only: [:create]
  resources :items, only: [:index, :new, :create, :edit, :update, :destroy]
end
