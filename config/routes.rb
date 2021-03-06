API_SUBDOMAIN = { subdomain: /\A(staging-)?api\Z/ }.freeze unless defined? API_SUBDOMAIN

BuckyBox::Application.routes.draw do
  apipie

  devise_for :admins,       controllers: { sessions: "admin/sessions" }
  devise_for :distributors, controllers: { sessions: "distributor/sessions", passwords: "distributor/passwords" }
  devise_for :customers,    controllers: { sessions: "customer/sessions", passwords: "customer/passwords" }

  get "/ping" => "application#ping"
  get "/delayed_job" => DelayedJobWeb, anchor: false
  get "/" => "api#index", constraints: API_SUBDOMAIN

  root to: "distributor/customers#index"

  namespace :sign_up_wizard do
    get "form"
    get "country"
    post "sign_up"
  end

  namespace :distributor do
    root to: "welcome#index"

    namespace :settings do
      get "organisation"
      get "webstore"
      post "webstore", action: "save_webstore"
      post "spend_limit_confirmation"

      resource :delivery_services, only: [:show, :create, :update, :destroy]

      namespace :products do
        resource :boxes, only: [:show, :create, :update]
        resource :box_items, only: [:show, :create, :update]
        resource :extra_items, only: [:show, :create, :update]
      end

      namespace :payments do
        resource :bank_deposit, controller: "bank_deposit", only: [:show, :update]
        resource :cash_on_delivery, controller: "cash_on_delivery", only: [:show, :update]
        resource :paypal, controller: "paypal", only: [:show, :update]
      end
    end

    namespace :notifications do
      post "dismiss_all", actions: "dismiss_all", as: "dismiss_all"
    end

    namespace :intro_tour do
      post "dismiss", actions: "dismiss", as: "dismiss"
    end

    namespace :reports do
      get "/",                               action: "index"
      get "transaction_history/:start/:to",  action: "transaction_history",      as: "transaction_history"
      get "customer_account_history/:to",    action: :customer_account_history,  as: "customer_account_history"
    end

    resource :billing, only: :show, controller: "billing" do
      get "invoice/:number", action: "invoice", as: "invoice"
    end
    resource :pricing, only: :update, controller: "pricing"

    resources :distributors,        only: :update
    resource  :bank_information,    only: :update
    resources :boxes,               except: [:index]
    resources :extras,              except: [:index, :show]

    resources :line_items, except: [:index, :show, :update] do
      collection do
        put "bulk_update", action: :bulk_update, as: "bulk_update"
      end
    end

    resources :deliveries

    resources :payments, only: [:index, :destroy] do
      collection do
        post "match_payments", action: "match_payments", as: "match_payments"
      end

      member do
        put "process_payments", action: "process_payments", as: "process_payments"
      end
    end

    resources :import_transactions, only: [:update] do
      member do
        get "load_more_rows/:position", action: "load_more_rows", as: "load_more_rows"
      end
    end

    resources :import_transaction_lists, only: [:destroy]

    resources :customers, except: [:edit] do
      collection do
        get "search",   action: :index, as: "search"
        get "tag/:tag", action: :index, as: "tag"
        post "email"
        post "export"
      end

      member do
        get :send_login_details
        get "impersonate"
        get "activity"
        get "edit_profile",             action: "edit_profile",             as: "edit_profile"
        put "update_profile",           action: "update_profile",           as: "update_profile"
        get "edit_delivery_details",    action: "edit_delivery_details",    as: "edit_delivery_details"
        put "update_delivery_details",  action: "update_delivery_details",  as: "update_delivery_details"
      end
    end

    resources :accounts, only: :edit do
      resources :orders, except: [:index, :show, :destroy] do
        member do
          put "deactivate"
          put "pause"
          post "remove_pause"
          put "resume"
          post "remove_resume"
        end
      end

      resources :boxes do
        member do
          get "extras"
        end
      end

      member do
        put "change_balance", action: :change_balance, as: "change_balance"
        get "transactions/:limit(/:more)", action: :transactions, as: "transactions"
        get "receive_payment", action: :receive_payment, as: "receive_payment"
        post "save_payment",   action: :save_payment, as: "save_payment"
      end
    end
  end

  namespace :customer do
    root to: "dashboard#index"

    get "dashboard",               controller: "dashboard", action: "index"
    get "order/:order_id/box/:id", controller: "dashboard", action: "box"

    put "update_contact_details",   controller: "customers",  action: "update_contact_details"
    put "update_delivery_address",  controller: "customers",  action: "update_delivery_address"
    put "update_password",          controller: "customers",  action: "update_password"

    resources :boxes, only: [:show] do
      member do
        get "extras"
      end
    end

    resources :orders, only: [:edit, :update] do
      member do
        put "pause"
        post "remove_pause"
        put "resume"
        post "remove_resume"
        put "deactivate"
      end
    end

    resources :accounts, only: [] do
      get "transactions/:limit(/:more)", action: :transactions, as: "transactions"
    end
  end

  namespace :admin do
    root to: "dashboard#index"

    resources :cron_logs, only: :index
    resources :style_sheet, only: :index

    resources :metrics, only: [:index] do
      collection do
        get "transactional_customers"
        get "sales"
      end
    end

    resources :distributors, only: [:index, :new, :create, :edit, :update] do
      member do
        get "impersonate"
      end

      collection do
        get "unimpersonate"
        get "country_setting/:id", controller: "distributors", action: "country_setting"
        get "tag/:tag", action: :index, as: "tag"
      end
    end

    resources :omni_importers do
      member do
        post "test"
      end
    end
  end

  namespace :api, path: "", defaults: { format: :json }, constraints: API_SUBDOMAIN do
    namespace :v1 do
      get  "ping"                => "base#ping"
      post "csp-report"          => "base#csp_report"
      get  "geoip(/:ip)"         => "base#geoip", constraints: { ip: %r{[^\/]+} } # accept IP including dots

      post "/customers/sign_in"
      resources :customers,         only: [:index, :show, :create, :update]
      resources :boxes,             only: [:index, :show]
      resources :delivery_services, only: [:index, :show]
      resources :orders,            only: [:index, :show, :create]
      resources :webstores,         only: [:index] # all webstores
      resource  :webstore,          only: [:show] # current webstore
      resources :deliveries,        only: [:index] do
        get :pending, on: :collection
      end
    end
  end

  # TODO: Legacy routes. As we move to all RESTful routes these should be removed.
  get "/distributor/deliveries/date/:date/view/:view",            controller: "distributor/deliveries", action: :index,                           as: "date_distributor_deliveries"
  post "/distributor/deliveries/date/:date/reposition",           controller: "distributor/deliveries", action: :reposition,                      as: "reposition_distributor_deliveries"
  post "/distributor/deliveries/update_status",                   controller: "distributor/deliveries", action: :update_status,                   as: "update_status_distributor_deliveries"
  post "/distributor/deliveries/make_payment",                    controller: "distributor/deliveries", action: :make_payment,                    as: "make_payment_distributor_deliveries"
  post "/distributor/deliveries/master_packing_sheet",            controller: "distributor/deliveries", action: :master_packing_sheet,            as: "master_packing_sheet_distributor_deliveries"

  post "/distributor/deliveries/export",                          controller: "distributor/export/deliveries",               action: :index, as: "export_distributor_deliveries"
  post "/distributor/deliveries/export_extras",                   controller: "distributor/export/extras",                   action: :index, as: "export_extras_distributor_deliveries"
  post "/distributor/deliveries/export_exclusions_substitutions", controller: "distributor/export/exclusions_substitutions", action: :index, as: "export_exclusions_substitutions_distributor_deliveries"
end
