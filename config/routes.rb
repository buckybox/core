BuckyBox::Application.routes.draw do
  devise_for :distributors, controllers: { sessions: 'distributor/sessions' }
  devise_for :customers,    controllers: { sessions: 'customer/sessions' }

  root to: 'bucky_box#index'

  namespace :market do
    get ':distributor_parameter_name',                  action: 'store',            as: 'store'
    get ':distributor_parameter_name/buy/:box_id',      action: 'buy',              as: 'buy'
    get ':distributor_parameter_name/customer_details', action: 'customer_details', as: 'customer_details'
    get ':distributor_parameter_name/payment',          action: 'payment',          as: 'payment'
    get ':distributor_parameter_name/success',          action: 'success',          as: 'success'
  end

  resources :distributors do
    resource :bank_information,    controller: 'distributor/bank_information',    only: :create
    resource :invoice_information, controller: 'distributor/invoice_information', only: :create
    resources :boxes,              controller: 'distributor/boxes',               except: [:index, :new, :show]
    resources :routes,             controller: 'distributor/routes',              except: [:index, :new, :show]
    resources :transactions,       controller: 'distributor/transactions',        only: :create

    resources :deliveries, controller: 'distributor/deliveries' do
      collection do
        get 'date/:date/view/:view',       action: :index,                as: 'date'
        post 'date/:date/reposition',      action: :reposition,           as: 'reposition'
        post 'update_status',              action: :update_status,        as: 'update_status'
        post 'export',                     action: :export,               as: 'export'
        post 'master_packing_sheet/:date', action: :master_packing_sheet, as: 'master_packing_sheet'
      end
    end

    resources :invoices, controller: 'distributor/invoices' do
      collection do
        get 'to_send', action: 'to_send', as: 'to_send'
        post 'do_send', action: 'do_send', as: 'do_send'
      end
    end

    resources :payments, controller: 'distributor/payments', only: [:create, :index] do
      collection do
        get 'upload_transactions', action: 'upload_transactions', as: 'upload_transactions'
        post 'process_upload', action: 'process_upload', as: 'process_upload'
        post 'create_from_csv', action: 'create_from_csv', as: 'create_from_csv'
      end
    end

    resources :customers, controller: 'distributor/customers' do
      collection do
        get 'search',   action: :index, as: 'search'
        get 'tag/:tag', action: :index, as: 'tag'
      end

      member  do
        get :send_login_details
      end
    end

    resources :accounts, controller: 'distributor/accounts', only: :edit do
      resources :orders, controller: 'distributor/orders', except: [:index, :show, :destroy] do
        member do
          put 'deactivate'
          put 'pause'
          post 'remove_pause'
        end
      end

      member do
        put 'change_balance', action: :change_balance, as: 'change_balance'
      end
      member do
        get 'receive_payment', :action => :receive_payment, :as => 'receive_payment'
        post 'save_payment', :action => :save_payment, :as => 'save_payment'
      end
    end

    resources :events, controller: 'distributor/dashboard' do
      member do
        post 'dismiss_notification'
      end
    end
  end

  namespace :distributor do
    root to: 'dashboard#index'
    get 'dashboard', constoller: 'dashboard', action: 'index'

    namespace :wizard do
      get 'business'
      get 'boxes'
      get 'routes'
      get 'payment'
      get 'billing'
      get 'success'
    end
  end

  resources :customers, controller: 'customer/customers', only: :update do
    resource  :address, controller: 'customer/address', only: :update

    resources :orders,  controller: 'customer/orders',  only: :update do
      member do
        put 'pause'
        post 'remove_pause'
      end
    end

    member do
      put 'update_password'
    end
  end

  namespace :customer do
    root to: 'dashboard#index'
    get 'dashboard',               controller: 'dashboard', action: 'index'
    get 'order/:order_id/box/:id', controller: 'dashboard',  action: 'box'
  end
end
