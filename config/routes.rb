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
end
