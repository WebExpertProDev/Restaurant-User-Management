# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    get '/', to: 'admin#index'
    resources :users
    resources :restaurants
  end

  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'sessions/registration'
  }

  get '/collections/:id', to: 'collections#list'
  get '/collections', to: 'collections#list_all'
  post '/collections', to: 'collections#create'
  post '/collections/:id/add', to: 'collections#add_restaurants'
  post '/collections/:id/remove', to: 'collections#remove_restaurants'
  post '/collections/:id/delete', to: 'collections#delete'

  get '/restaurants/:id', to: 'restaurants#detail'
  get '/restaurants/:cover/:location/:datetime',
      constraints: { location: /[\-0-9\.]+(.)+[\-0-9\.]+/ },
      to: 'restaurants#filter'

  get '/reservations', to: 'reservations#list'

  post '/reserve/lock', to: 'reservations#lock'
  post '/reserve', to: 'reservations#reserve'

  post '/partner-auth', to: 'auth#partner_auth'
end
