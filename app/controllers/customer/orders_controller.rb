class Customer::OrdersController < Customer::BaseController
  nested_belongs_to :customer
  actions :all

  respond_to :html, :xml, :json

  def home
    redirect_to customer_orders_path(current_customer)
  end

  def new
    #needs work
    @order = current_customer.account.orders.new
  end

  def update
    # Not allowing changes to the schedule at the moment
    # Will revisit when we have time to build a proper UI for it
    params[:order].delete(:frequency)

    update! { customer_orders_path(current_customer) }
  end
end
