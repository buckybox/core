class WebstoreController < ApplicationController
  before_filter :get_distributor
  before_filter :get_order_from_session, :except => [:store, :buy]

  def store
    @hide_sidebars = true
    @boxes = @distributor.boxes
    analytical.event('view_store', :with => {:distributor_id => @distributor.id})
  end

  def buy
    @box = Box.find(params[:box_id])
    @order = Order.new(:box => @box)
    analytical.event('begin_order', :with => {:distributor_id => @distributor.id, :box => @box.id})
  end

  def customer_details
    @customer = Customer.new if @customer.nil?
    @customer.email = params[:email]
    @customer.distributor = @distributor
    @address = @customer.build_address
  end

  def payment
  end

  def success
    @order.completed = true
    @order.save

    analytical.event('complete_order', :with => {:distributor_id => @distributor.id})
    session[:order_id] = nil
    @box = @order.box
  end

  private

  def get_order_from_session
    @order = Order.find(session[:order_id])
    @box = @order.box
    @customer = @order.customer
    unless @order
      redirect_to market_store_url(@distributor.parameter_name)
    end
  end

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
