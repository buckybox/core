class WebstoreController < ApplicationController
  layout 'customer'

  before_filter :check_distributor
  before_filter :get_webstore_order, except: [:store, :process_step]

  def store
    @boxes = @distributor.boxes.not_hidden
  end

  def process_step
    webstore = Webstore.new(self, @distributor)
    @webstore_order = webstore.order

    if webstore.process_params
      redirect_to action: webstore.next_step, distributor_parameter_name: @distributor.parameter_name
    end
  end

  def customise
    @stock_list = @distributor.line_items
    @box = @webstore_order.box
    @extras = @box.extras.not_hidden.alphabetically
  end

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
    @days = ScheduleRule::DAYS.map { |day| [day.to_s.titleize, ScheduleRule::DAYS.index(day)] }
    @order_frequencies = [
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
    @customer_name = (existing_customer? ? current_customer.name : '')
    @order_price = @webstore_order.order_price(current_customer)

    @address = (current_customer ? current_customer.address : '')
    @current_balance = current_customer ? current_customer.account.balance : Money.new(0)

    @city = @distributor.invoice_information.billing_city if @distributor.invoice_information
    @has_address = existing_customer?

    if @has_address
      @customer_phone_number = @address.phone_1
      @street_address = @address.address_1
      @street_address_2 = @address.address_2
      @suburb = @address.suburb
      @city = @address.city
      @post_code = @address.postcode
    end

    @closing_balance = @current_balance - @order_price
    @amount_due = @closing_balance
    @bank = @distributor.bank_information
    @payment_required = @closing_balance.negative?
  end

  def payment
    @order_price = @webstore_order.order_price(current_customer)
    @current_balance = (current_customer ? current_customer.account.balance : Money.new(0))
    @closing_balance = @current_balance - @order_price
    @amount_due = @closing_balance * -1
    @bank = @distributor.bank_information
    @payment_required = @closing_balance.negative?
  end

  def placed
    @customer = @webstore_order.customer
    @address = @customer.address
    @schedule_rule = @webstore_order.schedule_rule
  end

  private

  def existing_customer?
    current_customer && current_customer.persisted?
  end

  def active_orders?
    current_customer.present? && !current_customer.orders.active.count.zero?
  end

  def get_webstore_order
    webstore_order_id = session[:webstore][:webstore_order_id] if session[:webstore]
    @webstore_order = WebstoreOrder.find_by_id(webstore_order_id) if webstore_order_id
    redirect_to webstore_store_url and return unless @webstore_order
  end

  def check_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])

    if @distributor
      Time.zone = @distributor.time_zone
      Money.default_currency = Money::Currency.new(@distributor.currency)

      # So we don't have customers from other distributors trying to make orders in this store
      sign_out(current_customer) if current_customer && current_customer.distributor != @distributor
    end

    redirect_to 'http://www.buckybox.com/' and return if @distributor.nil? || !@distributor.active_webstore
  end
end
