class Customer::DashboardController < ApplicationController
  before_filter :authenticate_customer!
  layout 'customer'

  def index
    @customer     = current_customer
    @address      = @customer.address
    @orders       = @customer.orders
    @balance      = @customer.account.balance
    @transactions = @customer.transactions.limit(5)
    @distributor  = @customer.distributor
  end

  def box
    @box   = Box.find(params[:id])
    @order = Order.find(params[:order_id])

    respond_to do |format|
      if @box.distributor == current_customer.distributor
        format.json { render json: { order: @order, box: @box } }
      else
        format.json { render json: nil, status: :unprocessable_entity }
      end
    end
  end
end
