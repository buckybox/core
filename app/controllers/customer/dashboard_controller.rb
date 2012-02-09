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
end
