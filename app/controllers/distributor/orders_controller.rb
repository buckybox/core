class Distributor::OrdersController < InheritedResources::Base
  belongs_to :distributor

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to market_customer_details_url(@distributor.parameter_name, @order, :email => params[:email])}
      failure.html { redirect_to :back }
    end
  end
end
