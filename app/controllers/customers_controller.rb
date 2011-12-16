class CustomersController < InheritedResources::Base
  before_filter :authenticate_distributor!, :except => :create
  
  respond_to :html, :xml, :json, :except => [:index, :destroy]
  layout 'distributor'

  def create
    create! do |success, failure|
      success.html do
        @order = Order.find(session[:order_id])
        @order.update_attribute(:customer, @customer)
        redirect_to market_payment_url(@customer.distributor.parameter_name, @order)
      end

      failure.html { redirect_to :back }
    end
  end

  def update
    update! do |success, failure|
      success.html do
        account = @customer.accounts.where(:distributor_id => current_distributor.id).first
        redirect_to [current_distributor, account]
      end
      failure.html { render 'edit' }
    end
  end
end
