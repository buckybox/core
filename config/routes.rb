BuckyBox::Application.routes.draw do
  devise_for :distributors

  get 'home' => 'bucky_box#index', :as => 'home'

  root :to => 'bucky_box#index'
  
  resources :distributors
  
  namespace(:distributor) do
    root :to => 'dashboard#index'

    get 'dashboard' => 'dashboard#index'
  
    get 'wizard/business'
    get 'wizard/boxes'
    get 'wizard/routes'
    get 'wizard/payment'
    get 'wizard/billing'
    get 'wizard/success'
  end
end
