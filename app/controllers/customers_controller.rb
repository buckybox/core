class CustomersController < InheritedResources::Base
  respond_to :html, :xml, :json

  def create
    @order = Order.find(params[:order_id])
    @distributor = @order.distributor
    
    create! do |success, failure|
      success.html do
        @order.update_attribute(:customer, @customer)
        redirect_to market_payment_url(@distributor.parameter_name, @order)
      end
      failure.html { redirect_to :back }
    end
  end
end
