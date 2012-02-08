class Customer::DashboardController < Customer::BaseController
  def index
    @orders = current_customer.orders
    @balance = current_customer.account.balance
    @transactions = current_customer.transactions.limit(5)

    @address = current_customer.address
  end
end
