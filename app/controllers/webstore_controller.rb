class WebstoreController < ApplicationController
  before_filter :get_distributor
  before_filter :get_box, except: [:store, :success]

  def store
    @boxes = @distributor.boxes.not_hidden
  end

  def customise
    @box = Box.find(params[:box_id])
    @webstore_order = @distributor.webstore_orders.new(box: @box)
    @stock_list = @distributor.line_items
    @extras = @box.extras.alphabetically
  end

  def buy
    box_id = params[:box_id]

    add_to_cart(box_id: box_id, force_clear: true)
  end

  def customer_details
    if params[:buy]
      likes          = params[:buy][:likes]
      dislikes       = params[:buy][:dislikes]
      extras_one_off = params[:buy][:extras_one_off]
      extras         = params[:buy][:extra]

      add_to_cart(likes: likes, dislikes: dislikes, extras_one_off: extras_one_off, extras: extras)
    end

    session[:customer_return_to] = webstore_customer_details_url(@distributor.parameter_name)
  end

  def payment
    frequency  = params[:route][:frequency]
    start_date = params[:route][:start_date]

    if customer_signed_in?
      add_to_cart(frequency: frequency, start_date: start_date)
    else
      email = params[:customer_details][:email]
      customer   = params[:customer_details]

      if Customer.find_by_email(email)
        flash[:notice] = 'You email exists, please use another or log in first instead.'
        render :customer_details and return
      end

      add_to_cart(customer: customer, frequency: frequency, start_date: start_date)
    end

    order = create_order_from_cart(session[:cart])
    add_to_cart(box_id: @box.id, order_id: order.id, force_clear: true) if order.persisted?
  end

  def success
    @box = Box.find(session[:cart][:box_id])
    @order = Order.find(session[:cart][:order_id])
  end

  private

  def get_box
    if params[:box_id]
      @box = Box.find(params[:box_id])
    else
      @box = Box.find(session[:cart][:box_id])
    end
  end

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end

  def add_to_cart(args)
    session[:cart] = {} if args.delete(:force_clear) || session[:cart].blank?
    session[:cart].merge!(args)
  end

  def create_order_from_cart(cart_hash)
    ActiveRecord::Base.transaction do
      start_date = Date.parse(cart_hash.delete(:start_date))
      route      = Route.default_route_on(@distributor, start_date)

      if customer_signed_in?
        customer = current_customer
      else
        address_hash = cart_hash[:customer].delete('address')
        customer_hash = cart_hash.delete(:customer)

        customer_hash.merge!(route_id: route.id)
        customer = @distributor.customers.new(customer_hash)
        address = Address.new(address_hash.merge(customer: customer))

        customer.save!
      end

      account = customer.account
      extras = cart_hash.delete(:extras)["extras"]

      order = account.orders.new(cart_hash)
      order.order_extras = extras
      order.completed = true
      order.create_schedule(start_date, cart_hash[:frequency], [start_date.wday])

      order.save!

      return order
    end
  end
end
