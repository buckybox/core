class CustomersController < InheritedResources::Base
  before_filter :authenticate_distributor!, :except => :create

  respond_to :html, :xml, :json, :except => [:index, :destroy]
  layout 'distributor'

  #TODO : does this need a check to ensure the customer belongs to the current distributor - before chain or something similar?

  def create
    create! do |success, failure|
      success.html do
        @order = Order.find(session[:order_id])
        @order.customer = @customer
        @order.save
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

  def send_login_details
    resource.randomize_password
    resource.save

    if CustomerMailer.login_details(resource).deliver
      flash[:notice] = "Login details successfully sent"
    end

    redirect_to distributor_account_path(resource.distributor, resource.account)
  end
end
