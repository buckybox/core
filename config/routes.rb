BuckyBox::Application.routes.draw do
  devise_for :distributors, :controllers => {:sessions => "distributor/sessions"}
  devise_for :customers, :controllers => {:sessions => "customer/sessions"}

  get 'home' => 'bucky_box#index', :as => 'home'

  root :to => 'distributor/dashboard#index'

  namespace :market do
    get ':distributor_parameter_name',                  :action => 'store',            :as => 'store'
    get ':distributor_parameter_name/buy/:box_id',      :action => 'buy',              :as => 'buy'
    get ':distributor_parameter_name/customer_details', :action => 'customer_details', :as => 'customer_details'
    get ':distributor_parameter_name/payment',          :action => 'payment',          :as => 'payment'
    get ':distributor_parameter_name/success',          :action => 'success',          :as => 'success'
  end

  resources :distributors do
    resources :boxes,              :controller => 'distributor/boxes',               :except => :index
    resources :routes,             :controller => 'distributor/routes',              :except => :index
    resource :bank_information,    :controller => 'distributor/bank_information',    :only => :create
    resource :invoice_information, :controller => 'distributor/invoice_information', :only => :create
    resources :payments,           :controller => 'distributor/payments',            :only => :create
    resources :transactions,       :controller => 'distributor/transactions',        :only => :create

    resources :deliveries,                 :controller => 'distributor/deliveries' do
      collection do
        get 'date/:date/view/:view',       :action => :index, :as => 'date'
        post 'date/:date/reposition',      :action => :reposition, :as => 'reposition'
        post 'update_status',              :action => :update_status, :as => 'update_status'
        post 'master_packing_sheet/:date', :action => :master_packing_sheet, :as => 'master_packing_sheet'
      end
    end

    resources :accounts, :controller => 'distributor/accounts' do
      resources :orders, :controller => 'distributor/orders', :except => [:index, :show]

      collection do
        get 'search',    :action => :index, :as => 'search'
        get 'tag/:tag',  :action => :index, :as => 'tag'
      end
    end

    resources :events, :controller => 'distributor/dashboard' do
      member do
        post 'dismiss_notification' => 'distributor/dashboard', :action => 'dismiss_notification'
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

  get 'customer', :controller => 'customer/orders', :action => 'home',  :as => 'customer_root'

  resources :customers do
    resources :orders, :controller => 'customer/orders'
    member  do
      get :send_login_details
    end
    resource :addresses, :controller => 'customer/addresses'
  end

  resources :orders
end
