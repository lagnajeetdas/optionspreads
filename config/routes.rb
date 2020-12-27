Rails.application.routes.draw do


  resources :stocks
  devise_for :users
  get 'home/index'
  root 'home#index'
  get 'home/about'

  post "/" => 'home#index'
  post "targetprice", to: "stocks#gettarget"
  #get "/targetprice" => 'stocks#gettarget', as: 'targetprice'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
 