class Customer::OrdersController < Customer::BaseController
  belongs_to :customer

  respond_to :html, :xml, :json

  def update
    params[:order].delete(:frequency)

    update! { customer_orders_path(current_customer) }
  end

  protected

  def collection
    @orders ||= end_of_association_chain.active
  end
end
