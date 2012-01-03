BuckyBox::Application.routes.draw do
  devise_for :distributors, :controllers => {:sessions => "distributor/sessions"}

  get 'home' => 'bucky_box#index', :as => 'home'

  root :to => 'bucky_box#index'

  namespace :market do
    get ':distributor_parameter_name',                  :action => 'store',            :as => 'store'
    get ':distributor_parameter_name/buy/:box_id',      :action => 'buy',              :as => 'buy'
    get ':distributor_parameter_name/customer_details', :action => 'customer_details', :as => 'customer_details'
    get ':distributor_parameter_name/payment',          :action => 'payment',          :as => 'payment'
    get ':distributor_parameter_name/success',          :action => 'success',          :as => 'success'
  end

  resources :distributors do
    resource :bank_information,    :controller => 'distributor/bank_information'
    resource :invoice_information, :controller => 'distributor/invoice_information'
    resources :boxes,              :controller => 'distributor/boxes'
    resources :routes,             :controller => 'distributor/routes'
    resources :orders,             :controller => 'distributor/orders'
    resources :payments,           :controller => 'distributor/payments', :only => :create
    resources :transactions,       :controller => 'distributor/transactions', :only => :create

    resources :deliveries,         :controller => 'distributor/deliveries' do
      collection do
        get 'date/:date', :action => :index, :as => 'date'
      end
    end

    resources :accounts,           :controller => 'distributor/accounts' do
      collection do
        get 'search',   :action => :index, :as => 'search'
        get 'tag/:tag', :action => :index, :as => 'tag'
      end
    end

    resources :events,             :controller => 'distributor/dashboard' do
      member do
        post 'dismiss_notification'=> 'distributor/dashboard', :action => 'dismiss_notification'
      end
    end
  end

  namespace :distributor do
    root :to => 'dashboard#index'

    get 'dashboard' => 'dashboard#index'

    namespace :wizard do
      get 'business'
      get 'boxes'
      get 'routes'
      get 'payment'
      get 'billing'
      get 'success'
    end
  end

  resources :customers do
    resource :addresses, :controller => 'customer/addresses'
  end

  resources :orders
end
