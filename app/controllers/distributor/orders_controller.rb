class Distributor::OrdersController < Distributor::BaseController
  belongs_to :distributor

  skip_before_filter :authenticate_distributor!, :only => [:create]

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to market_customer_details_url(@distributor.parameter_name, @order, :email => params[:email])}
      failure.html { redirect_to :back }
    end
  end

  protected

  def collection
    @orders ||= end_of_association_chain.completed
  end
end
