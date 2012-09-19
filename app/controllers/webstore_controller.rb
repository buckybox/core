class WebstoreController < ApplicationController
  before_filter :get_distributor
  before_filter :get_webstore_order, except: [:store]

  def store
    session[:webstore] = nil
    @boxes = @distributor.boxes.not_hidden
  end

  def process_step
    webstore = Webstore.new(@distributor, session, request.remote_ip)
    webstore.process_params(params)

    session[:webstore] = webstore.to_session

    redirect_to action: webstore.next_step, distributor_parameter_name: @distributor.parameter_name
  end

  def customise
    @stock_list = @distributor.line_items
    @box = @webstore_order.box
    @extras = @box.extras.alphabetically
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
    @days = Bucky::Schedule::DAYS.map { |day| [day[0..2].to_s.titleize, Bucky::Schedule::DAYS.index(day)] }
    @order_frequencies = [
      ['Delivery weekly on...', :weekly],
      ['Delivery 2 weeks on...', :fortnightly],
      ['Delivery monthly on...', :monthly],
      ['Deliver once', :single]
    ]
    @extra_frequencies = [
      ['Include Extra Items with EVERY delivery', false],
      ['Include Extra Items with NEXT delivery only', true]
    ]
  end

  def complete
    @order_price = @webstore_order.order_price
    @amount_due = @order_price
    if current_customer
      @current_balance = current_customer.account.balance
      @closing_balance = @current_balance - @order_price
      @amount_due = @closing_balance * -1
    end
    @bank = @distributor.bank_information
  end

  def placed
    @customer = @webstore_order.customer
    @address = @customer.address
    @schedule = @webstore_order.schedule

    flash[:notice] = 'Your order has been placed'
  end

  private

  def get_webstore_order
    webstore_order_id = session[:webstore][:webstore_order_id] if session[:webstore]
    @webstore_order = WebstoreOrder.find(webstore_order_id) if webstore_order_id
  end

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
