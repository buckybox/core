class WebstoreController < ApplicationController
  layout 'customer'

  before_filter :distributor_has_webstore?
  before_filter :setup_by_distributor
  before_filter :distributors_customer?, except: [:store, :checkout]

  def store
    store = Webstore::Store.new(distributor: current_distributor, logged_in_customer: logged_in_customer)
    @current_customer = store.customer
    products = store.products
    render 'store', locals: {  webstore_products: Webstore::ProductDecorator.decorate_collection(products) }
  end

  def start_checkout
    checkout = Webstore::Checkout.new(distributor: current_distributor, logged_in_customer: logged_in_customer)
    @current_customer = checkout.customer
    distributors_customer?
    checkout.add_product!(params[:product_id]) ? successful_new_checkout(checkout) : failed_new_checkout
  end

  def customise_order
    render 'customise_order', locals: {
      order: current_order.decorate,
      customise_cart: Webstore::Customise.new(cart: current_cart)
    }
  end

  def save_order_customisation
    args = { cart: current_cart }.merge(params[:webstore_customise])
    customise_cart = Webstore::Customise.new(args)
    customise_cart.save ? successful_customisation : failed_customisation(customise_cart)
  end

  def authorisation
    render 'authorisation', locals: {
      order: current_order.decorate,
      customer_authorisation: Webstore::Authorisation.new(cart: current_cart)
    }
  end

  def save_authorisation
    args = { cart: current_cart }.merge(params[:webstore_authorisation])
    customer_authorisation = Webstore::Authorisation.new(args)
    customer_authorisation.save ? successful_authorisation : failed_authorisation(customer_authorisation)
  end

  #--- Private

  def successful_authorisation
    redirect_to webstore_delivery_options_path
  end

  def failed_authorisation(customer_authorisation)
    flash[:alert] = 'We\'re sorry there was an error with your credentials.'
    render 'authorisation', locals: {
      order: current_order.decorate,
      customise_cart: customise_cart
    }
  end

  def successful_customisation
    redirect_to webstore_authorisation_path
  end

  def failed_customisation(customise_cart)
    flash[:alert] = 'We\'re sorry there was an error customising your order.'
    render 'customise_order', locals: {
      order: current_order.decorate,
      customise_cart: customise_cart
    }
  end

  def successful_new_checkout(checkout)
    session[:cart_id] = checkout.cart_id
    redirect_to webstore_customise_order_path
  end

  def failed_new_checkout
    flash[:alert] = 'We\'re sorry there was an error starting your order.'
    redirect_to webstore_store_path
  end

  def current_cart
    @current_cart ||= Webstore::Cart.find(session[:cart_id])
  end

  def current_order
    @current_order ||= current_cart.order
  end

  alias_method :logged_in_customer, :current_customer
  def current_customer
    @current_customer ||= current_cart.customer
  end

  def distributors_customer?
    valid_customer = (current_customer.distributor == current_distributor)
    alert_message = 'This account is not for this webstore. Please logout first then try your purchase again.'
    redirect_to webstore_store_path, alert: alert_message and return unless valid_customer
  end

  def distributor_has_webstore?
    active_webstore = !current_distributor.nil? && current_distributor.active_webstore
    redirect_to Figaro.env.marketing_site_url and return unless active_webstore
  end

  def setup_by_distributor
    Time.zone = current_distributor.time_zone
    Money.default_currency = Money::Currency.new(current_distributor.currency)
  end

  def current_distributor
    @distributor ||= Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end

  #-------------------------

  def delivery
    @routes = @distributor.routes
    @route_selections = @distributor.routes.map { |route| [route.name_days_and_fee, route.id] }
    @selected_route_id = current_customer.route_id if active_orders?
    @days = view_context.order_dates_grid
    @order_frequencies = [
      ['- Select delivery frequency -', nil],
      ['Deliver weekly on...', :weekly],
      ['Deliver every 2 weeks on...', :fortnightly],
      ['Deliver monthly', :monthly],
      ['Deliver once', :single]
    ]
    @extra_frequencies = [
      ['Include Extra Items with EVERY delivery', false],
      ['Include Extra Items with NEXT delivery only', true]
    ]
  end

  def complete
    if session[:webstore].has_key? :address
      session[:webstore][:address].each do |key, value|
        instance_variable_set("@#{key}", value) if value
      end
    end

    @name ||= existing_customer? && current_customer.name
    @address ||= current_customer && current_customer.address
    @city ||= @distributor.invoice_information.billing_city if @distributor.invoice_information

    @has_address = existing_customer?

    if @has_address
      @phone_number = @address.phones.default_number
      @phone_type = @address.phones.default_type
      @street_address = @address.address_1
      @street_address_2 = @address.address_2
      @suburb = @address.suburb
      @city = @address.city
      @postcode = @address.postcode
      @delivery_note = @address.delivery_note
    end

    @payment_method = session[:webstore][:payment_method]
    @order_price = @webstore_order.order_price(current_customer)
    @current_balance = (current_customer ? current_customer.account.balance : Money.new(0))
    @closing_balance = @current_balance - @order_price
    @amount_due = @closing_balance
    @payment_required = @closing_balance.negative?
  end

  def placed
    CustomerLogin.track(@webstore_order.customer) unless current_admin.present?
    sign_in(@webstore_order.customer)

    raise "Customer should be signed in at this point" unless customer_signed_in?
    raise "Current customer should be set" if current_customer != @webstore_order.customer
    raise "Customer should have an account" unless current_customer.account

    @payment_method = session[:webstore][:payment_method]
    @order_price = @webstore_order.order_price(current_customer)
    @current_balance = (current_customer ? current_customer.account.balance : Money.new(0))
    @closing_balance = @current_balance - @order_price
    @amount_due = -@closing_balance
    @bank = @distributor.bank_information
    @payment_required = @closing_balance.negative?

    @customer = @webstore_order.customer
    @address = @customer.address
    @schedule_rule = @webstore_order.schedule_rule

    flash[:notice] = 'Your order has been placed'
  end

private

  def existing_customer?
    current_customer && current_customer.persisted?
  end

  def active_orders?
    current_customer.present? && !current_customer.orders.active.count.zero?
  end
end
