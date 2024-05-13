require 'sidekiq/web'

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
  get  '/terms',                                to: 'static_pages#terms'
  get  '/policy',                               to: 'static_pages#policy'
  get  'shopping/new',                          to: 'shopping_records#new'
  post 'shopping/new/back',                     to: 'shopping_records#back_new'
  post 'shopping/new/confirm',                  to: 'shopping_records#confirm'
  get  'shopping/index',                        to: 'shopping_records#index'
  get  'shopping/:hashid/progress',             to: 'shopping_records#edit', as: 'shopping_progress'
  post 'shopping/progress/back',                to: 'shopping_records#back_edit'
  post 'shopping/progress/confirm',             to: 'shopping_records#edit_confirm'
  get  'shopping/result_group',                 to: 'shopping_records#result_group'
  get  'shopping/result/:date',                 to: 'shopping_records#result',      as: 'shopping_result'
  get  'shopping/result/:hashid/show',          to: 'shopping_records#show',        as: 'shopping_results'
  get  'shopping/result/:hashid/location/new',  to: 'shopping_locations#new',       as: 'new_shopping_location'
  get  'shopping/result/:hashid/location/edit', to: 'shopping_locations#edit',      as: 'edit_shopping_location'
  resources :shopping_records, only: [:create, :update, :destroy], param: :hashid
  resources :shopping_locations, only: [:create, :update, :destroy], param: :hashid
  resources :items, only: [:index, :new, :create, :edit, :update, :destroy], param: :hashid
  resources :notification_target_users, only: [:index, :new, :create, :destroy], param: :hashid do
    get :confirm_email, on: :collection
    get :resend_email_confirmation, as: 'resend_email', on: :member
  end
  authenticate :user, lambda { |user| user.admin? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
