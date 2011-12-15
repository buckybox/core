class OrdersController < InheritedResources::Base
  respond_to :html, :xml, :json, :only => [:create]

  def create
    create! do |success, failure|
      success.html { 
        session[:order_id] = @order.id
        if customer = Customer.find_by_email(params[:email])
          @order.customer = customer
          @order.save
          redirect_to market_payment_path(@order.distributor.parameter_name)
        else
          redirect_to market_customer_details_path(@order.distributor.parameter_name, :email => params[:email])
        end
      }
      failure.html { redirect_to :back }
    end
  end
end
