class CustomersController < InheritedResources::Base
  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html do
        @order = Order.find(params[:order_id])
        @order.update_attribute(:customer, @customer)
        @distributor = @order.distributor

        redirect_to market_payment_url(@distributor.parameter_name, @order)
      end

      failure.html { redirect_to :back }
    end
  end

  def update
    update! do |success, failure|
      success.html do
        @order = Order.find(params[:order_id])
        @order.update_attribute(:customer, @customer)
        @distributor = @order.distributor

        redirect_to market_payment_url(@distributor.parameter_name, @order)
      end
      failure.html { redirect_to :back }
    end
  end
end
