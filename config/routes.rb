Rails.application.routes.draw do

  resources :optionbookmarks
  get 'home/about'
  resources :stocks
  resources :home
  devise_for :users
  resources :options
  resources :screeners
  get 'home/index'
  root 'home#index'
  #get :autocomplete_universe_displaysymbol, :on => :collection

  #get 'home/show'

  post "/" => 'home#index'
  post "targetprice", to: "stocks#gettarget"
  post "addoptionbookmark", to: "optionbookmarks#addbookmark"
  #get "/targetprice" => 'stocks#gettarget', as: 'targetprice'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
 