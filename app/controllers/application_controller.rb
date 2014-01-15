class ApplicationController < ActionController::Base
  protect_from_forgery

  unless Rails.env.development?
    analytical modules: [:google], use_session_store: true
  else
    analytical modules: [], use_session_store: true
  end

  before_filter :set_user_time_zone
  before_filter :customer_smart_sign_in

  layout :layout_by_resource


protected

  def send_csv(filename, data)
    type = 'text/csv; charset=utf-8; header=present'

    send_data(data, type: type, filename: "#{filename}.csv")
  end

  def tracking
    @tracking ||= Bucky::Tracking.instance
  end

  def current_customers(options = {})
    # return {} unless current_customer

    cookie = cookies.signed[:current_customers] || []

    if options[:all]
      if current_customer
        Customer.where(email: current_customer.email).sort_by do |customer|
          # signed in accounts first
          customer.id.in?(cookie) ? 0 : 1
        end
      else
        []
      end
    else
      cookie.map do |customer_id|
        Customer.find(customer_id)
      end
    end
  end
  helper_method :current_customers

  def customer_smart_sign_in
    guessed_distributor = if params[:switch_to_distributor] && customer_can_swith_account?
      Distributor.find_by(parameter_name: params[:switch_to_distributor])
    # else
    #   binding.pry if current_distributor
    #   current_distributor
    end

    return unless guessed_distributor

    guessed_customer = current_customers.detect { |c| c.distributor == guessed_distributor }
    guessed_customer_id = guessed_customer && guessed_customer.id
    unless guessed_customer_id
      sign_out :customer
      redirect_to new_customer_session_url(distributor: guessed_distributor.parameter_name) and return
    end

    current_customer_id = current_customer && current_customer.id
    return if current_customer_id && current_customer_id == guessed_customer_id

    if params[:distributor_parameter_name]
      params[:distributor_parameter_name] = guessed_distributor.parameter_name
    end

    sign_in Customer.find(guessed_customer_id)
    redirect_to url_for(params)
  end

  def customer_has_incomplete_cart?
    !!session[:cart_id]
  end

  def customer_can_swith_account?
    !customer_has_incomplete_cart?
  end
  helper_method :customer_can_swith_account?

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

  def account_transactions(account, offset=0, limit=6, dummy=true)
    transactions = []
    if cookies["transaction_order"].blank? || cookies["transaction_order"] == 'date_processed'
      transactions = account.transactions.ordered_by_created_at.limit(limit).offset(offset)
    else
      transactions = account.transactions.ordered_by_display_time.limit(limit).offset(offset)
    end
    transactions = [Transaction.dummy(0, "Opening Balance", @account.created_at)] if transactions.empty? && dummy
    transactions
  end

private

  def set_user_time_zone
    distributor = current_distributor || current_customer.try(:distributor)

    if distributor.present? && distributor.time_zone.present?
      Time.zone = distributor.time_zone
    else
      Time.zone = BuckyBox::Application.config.time_zone
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    # Clear? No? Oh, that's weird for this app. :S

    if resource_or_scope == :admin
      admin_root_url
    elsif resource_or_scope == :distributor
      distributor_root_url
    elsif resource_or_scope == :customer
      if current_customer
        distributor_param_name = current_customer.distributor.parameter_name
      else
        request.referer =~ /\/webstore\/([^\/]+).*/
        distributor_param_name = $1
      end

      if distributor_param_name.blank?
        customer_root_url
      else
        webstore_store_url(distributor_param_name)
      end
    else
      Figaro.env.marketing_site_url # Shouldn't happen but better than nothing.
    end
  end
end
