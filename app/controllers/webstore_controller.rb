class WebstoreController < ApplicationController
  layout 'customer'

  before_filter :check_access
  before_filter :setup_by_distributor

  after_filter :save_cart_id

  def store
    setup_cart(current_customer)
    render 'store', locals: {  webstore_products: webstore_products }
  end

  def start_order
    current_cart.add_product(product_id: params[:product_id])
    current_cart.save ? successful_new_order : failed_new_order
  end

  def customise
    render 'customise', locals: {
      order: current_order.decorate,
      customise_cart: Webstore::Customise.new(cart: current_cart)
    }
  end

  def save_customisations
    args = { cart: current_cart }.merge(params[:webstore_customise])
    customise_cart = Webstore::Customise.new(args)
    customise_cart.save ? successful_customisation : failed_customisation(customise_cart)
  end

  #--- Private

  def id_logger
    puts ">"*100
    puts "Action: #{action_name}   Cart Before ID: #{current_cart.id}   Session ID: #{session[:cart_id]}   Cart After ID: #{Webstore::Cart.find(session[:cart_id]).id}"
    puts "<"*100
  end

  def setup_cart(customer)
    cart = Webstore::Cart.new(customer: customer)
    cart.save
  end

  def webstore_products
    products = Webstore::Product.build_distributors_products(current_distributor)
    Webstore::ProductDecorator.decorate_collection(products)
  end

  def successful_new_order
    redirect_to webstore_customise_path
  end

  def failed_new_order
    flash[:error] = 'We\'re sorry there was an error starting your order.'
    redirect_to webstore_store_path
  end

  def successful_customisation
    redirect_to webstore_login_path
  end

  def failed_customisation(customise_cart)
    flash[:error] = 'We\'re sorry there was an error starting your order.'
    render 'customise', locals: {
      order: current_order.decorate,
      customise_cart: customise_cart
    }
  end

  def current_cart
    @current_cart ||= Webstore::Cart.find(session[:cart_id])
  end

  def current_order
    @current_order ||= current_cart.order
  end

  def current_customer
    @current_customer ||= (current_cart ? current_cart.customer : wrap_real_customer(super))
  end

  def wrap_real_customer(real_customer)
    Webstore::Customer.new(customer: real_customer)
  end

  def check_access
    active_webstore = !current_distributor.nil? && current_distributor.active_webstore
    redirect_to Figaro.env.marketing_site_url and return unless active_webstore
    check_customer_access
  end

  def check_customer_access
    real_customer = current_cart.real_customer
    sign_out(real_customer) if current_cart.distributor != current_distributor
  end

  def current_distributor
    @distributor ||= Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end

  def setup_by_distributor
    Time.zone = current_distributor.time_zone
    Money.default_currency = Money::Currency.new(current_distributor.currency)
  end

  def save_cart_id
    session[:cart_id] = current_cart.id
  end

  #-------------------------

  def customise_error
    customise
    render :customise
  end

  def login
    @registered_options = [
      ["I'm a new customer", 'new'],
      ["I'm a returning customer", 'returning']
    ]
    @checked = @registered_options.first.last
  end

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
