class MarketController < ApplicationController
  before_filter :get_distributor
  before_filter :get_order_from_session, :except => [:store, :buy]

  def store
    @hide_sidebars = true
    @boxes = @distributor.boxes
    analytical.event('view_store', :with => {:distributor_id => @distributor.id})
  end

  def buy
    @box = Box.find(params[:box_id])
    @order = @distributor.orders.new(:box => @box)
    analytical.event('begin_order', :with => {:distributor_id => @distributor.id, :box => @box.id})
  end

  def customer_details
    @customer.email = @params[:email]
    @address = @customer.build_address
  end

  def payment
  end

  def success
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

  def get_order_from_session
    @order = Order.find(session[:order_id])
    @box = @order.box
    @customer = @order.customer
    unless @order
      redirect_to market_store_path(@distributor.parameter_name)
    end
  end

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
