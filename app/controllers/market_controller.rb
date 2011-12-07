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

    @box = @order.box
  end

  private

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
