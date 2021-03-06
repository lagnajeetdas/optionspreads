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
  post "roi_visualizer", to: "home#load_roi_visualizer"
  post "calc_spreads", to: "home#calculate_spreads"
  post "get_targets_for_watchlist", to: "stocks#gettarget_bulk"
  #get "roi_json", to: "stocks#get_roi_json"
  #resources :home do
  #  get :autocomplete_universe_displaysymbol, :on => :collection
  #end
  #get "/targetprice" => 'stocks#gettarget', as: 'targetprice'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
 