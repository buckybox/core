class MarketController < ApplicationController
  before_filter :get_distributor

  def store
    @hide_sidebars = true
    @boxes = @distributor.boxes
    analytical.event('view_store', :with => {:distributor_id => @distributor.id})
  end

  def buy
    @box = Box.find(params[:box_id])
    @order = @distributor.orders.new(:box => @box)
    analytical.event('begin_order', :with => {:distributor_id => @distributor.id, :box => @box.id})
    #TODO: save order_id in session and use that for the rest of the process
  end

  def customer_details
    #TODO: restrict to orders that aren't completed - load from session, not query string
    @order = Order.find(params[:order_id])
    @box = @order.box

    @customer = Customer.find_by_email(params[:email])

    if @customer
      @address = @customer.address
    else
      @customer = Customer.new(:email => params[:email])
      @address = @customer.build_address
    end
  end

  def payment
    @order = Order.find(params[:order_id])
    @box = @order.box
    @customer = @order.customer
  end

  def success
    @order = Order.find(params[:order_id])
    
    @customer = @order.customer
    account = @customer.accounts.where(:distributor_id => @distributor.id).first
    account = @customer.accounts.create(:distributor => @distributor) unless account

    @order.account = account
    @order.completed = true
    @order.save

    analytical.event('complete_order', :with => {:distributor_id => @distributor.id})
    #TODO: clear order from session
    @box = @order.box
  end

  private

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
