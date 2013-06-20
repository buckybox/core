class WebstoreController < ApplicationController
  layout 'customer'

  before_filter :setup_by_distributor
  before_filter :check_if_webstore_active

  def store
    webstore_session
    render 'store', locals: {  webstore_products: webstore_products }
  end

  def start_order
    ws = Webstore::Session.new(box_id: params['box_id'], customer: current_customer)
    ws.save ? successful_new_order : failed_new_order
  end

  def customise
    order = webstore_session.order
    render 'customise', locals: { order: order.decorate, customise_order: customise_order(order) }
  end

  #--- Private

  def webstore_products
    products = Webstore::Product.build_distributors_products(distributor)
    Webstore::ProductDecorator.decorate_collection(products)
  end

  def successful_new_order
    redirect_to webstore_customise_path
  end

  def failed_new_order
    flash[:error] = 'We\'re sorry there was an error starting your order.'
    redirect_to webstore_store_path
  end

  def customise_order(order)
    Webstore::Customise.new(order: order)
  end

  def current_customer
    @current_customer ||= (super || webstore_session.customer)
  end

  def webstore_customer_id(args)
    args['guest_customer_id']
  end

  def save_webstore_session(webstore_session)
    session[:webstore_session_id] = webstore_session.save
  end

  def webstore_session
    @webstore_session ||= begin
      Webstore::Session.find_or_create(session[:webstore_session_id])
    end
  end

  def setup_by_distributor
    if distributor
      set_defaults(distributor)
      check_customer(distributor, current_customer)
    end
  end

  def check_if_webstore_active
    if distributor.nil? || !distributor.active_webstore
      redirect_to Figaro.env.marketing_site_url and return
    end
  end

  def set_defaults(distributor)
    Time.zone = distributor.time_zone
    Money.default_currency = Money::Currency.new(distributor.currency)
  end

  def check_customer(distributor, customer)
    sign_out(customer) if !customer.guest? && customer.distributor != distributor
  end

  def distributor
    @distributor ||= Distributor.find_by_parameter_name(params[:distributor_parameter_name])
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
