class MarketController < ApplicationController
  before_filter :get_distributor

  def store
    @hide_sidebars = true
    @boxes = @distributor.boxes
  end

  def buy
    @box = Box.find(params[:box_id])
    @order = @distributor.orders.new(:box => @box)
  end

  def customer_details
    @order = Order.find(params[:order_id])
    @box = @order.box
    @customer = Customer.new
    @address = @customer.build_address
  end

  def payment
    @order = Order.find(params[:order_id])
    @box = @order.box
    @customer = @order.customer
  end

  def success
    @order = Order.find(params[:order_id])
    @order.completed = true
    puts "-"*20
    puts @order.inspect
    @order.save
    puts @order.errors.messages

    @box = @order.box
    @customer = @order.customer
  end

  private

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
