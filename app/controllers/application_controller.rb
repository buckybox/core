class ApplicationController < ActionController::Base
  protect_from_forgery

  if Rails.env.production? || Rails.env.staging?
    before_bugsnag_notify :add_user_info_to_bugsnag
  end

  attr_reader :current_currency

  before_action :set_user_time_zone
  before_action :customer_smart_sign_in

  if Rails.env.development?
    analytical modules: [], use_session_store: true
  else
    analytical modules: [:google], use_session_store: true
  end

  layout :layout_by_resource

protected

  before_action def set_locale
    I18n.locale = find_locale
  end

  before_action def set_currency
    @current_currency = find_currency
    CrazyMoney::Configuration.current_currency = current_currency
  end

  def send_csv(filename, data)
    type = 'text/csv; charset=utf-8; header=present'

    send_data(data, type: type, filename: "#{filename}.csv")
  end

  def tracking
    @tracking ||= Bucky::Tracking.instance
  end

  # @param options
  #   current: Include current_customer
  #   all: Include signed off accounts
  # @return [Array] List of customer account
  def current_customers(options = {})
    options = { current: true }.merge!(options)

    cookie = cookies.signed[:current_customers] || []

    customers = if options[:all]
      if current_customer
        Customer.where(email: current_customer.email).sort_by do |customer|
          # signed in accounts first
          customer.id.in?(cookie) ? 0 : 1
        end
      end
    else
      cookie.map { |customer_id| Customer.find(customer_id) }
    end || []

    customers.delete(current_customer) unless options[:current]

    customers
  end
  helper_method :current_customers

  def customer_smart_sign_in
    # guess distributor
    guessed_distributor = if params[:switch_to_distributor]
      Distributor.find_by(parameter_name: params[:switch_to_distributor])
    end
    return unless guessed_distributor

    # guess customer
    guessed_customer = current_customers.detect { |customer| customer.distributor == guessed_distributor }
    guessed_customer_id = guessed_customer && guessed_customer.id
    unless guessed_customer_id
      sign_out :customer
      redirect_to new_customer_session_url(distributor: guessed_distributor.parameter_name) and return
    end

    current_customer_id = current_customer && current_customer.id
    return if current_customer_id && current_customer_id == guessed_customer_id

    # update URL for guesed distributor
    if params[:distributor_parameter_name]
      params[:distributor_parameter_name] = guessed_distributor.parameter_name
    end

    # sign in guesed customer
    sign_in Customer.find(guessed_customer_id)
    redirect_to url_for(params)
  end

  def attempt_customer_sign_in(email, password, options = {})
    customer = Customer.find_by(email: email, distributor_id: current_distributor.id)
    return if !customer || !customer.valid_password?(password)
    customer if customer_sign_in(customer, options)
  end

  def customer_sign_in(customer, options = {})
    return if current_customer == customer

    options = { no_track: false }.merge(options)
    CustomerLogin.track(customer) unless options[:no_track]

    sign_in(customer)
  end

  def layout_by_resource
    if devise_controller?
      "#{resource_name}_devise"
    else
      super
    end
  end

  def account_transactions(account, offset = 0, limit = 6, dummy = true)
    transactions = if cookies["transaction_order"].blank? || cookies["transaction_order"] == 'date_processed'
      account.transactions.ordered_by_created_at.limit(limit).offset(offset)
    else
      account.transactions.ordered_by_display_time.limit(limit).offset(offset)
    end
    transactions = [Transaction.dummy(0, "Opening Balance", @account.created_at)] if transactions.empty? && dummy
    transactions
  end

private

  def set_user_time_zone
    distributor = current_distributor || current_customer.try(:distributor)

    Time.zone = if distributor.present? && distributor.time_zone.present?
      distributor.time_zone
    else
      BuckyBox::Application.config.time_zone
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    case resource_or_scope
    when :admin
      admin_root_url
    when :distributor
      distributor_root_url
    when :customer
      if current_customer && distributor = current_customer.distributor
        if distributor.active_webstore?
          distributor.webstore_url
        else
          new_customer_session_url(distributor: distributor.parameter_name)
        end
      else
        customer_root_url
      end
    else
      raise "should not happen"
    end
  end

  def add_user_info_to_bugsnag(notification)
    # Set the user that this bug affected
    # Email, name and id are searchable on bugsnag.com
    notification.user = {
      number: current_customer.try(:number),
    }

    # Add some app-specific data which will be displayed on a custom
    # "Diagnostics" tab on each error page on bugsnag.com
    notification.add_tab(:diagnostics, {
                           distributor_id: current_distributor.try(:id),
                           distributor_name: current_distributor.try(:name),
                           customer_id: current_customer.try(:id),
                           customer_name: current_customer.try(:name),
                         })
  end

  def find_locale
    return params[:locale] if params[:locale].present? # NOTE: for debugging purpose
    return :en if Rails.env.test?
    return :en if current_admin && current_distributor && current_customer
    return current_customer.locale if current_customer

    # Devise pages
    if params[:controller].start_with?("customer/") && params[:distributor].is_a?(String)
      distributor = Distributor.find_by(parameter_name: params[:distributor])
      return distributor.locale if distributor # NOTE: nasty bots send rubbish distributor param
    end

    I18n.default_locale # fallback
  end

  def find_currency
    CrazyMoney::Configuration.current_currency = if current_distributor
      current_distributor.currency
    elsif current_customer
      current_customer.currency
    end
  end
end
