class Distributor::CustomersController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json

  def new
    new! do
      @address = @customer.build_address
    end
  end

  def create
    create! do
      distributor_customers_url(current_distributor)
    end
  end

  def update
    update! { distributor_customer_url(current_distributor, @customer) }
  end

  def show
    show! do
      @address      = @customer.address
      @account      = @customer.account
      @transactions = @account.transactions
      @orders       = @account.orders.completed.active
      @deliveries   = @account.deliveries
    end
  end

  def send_login_details
    @customer = Customer.find(params[:id])

    @customer.randomize_password
    @customer.save

    if CustomerMailer.login_details(@customer).deliver
      flash[:notice] = "Login details successfully sent"
    end

    redirect_to distributor_customer_url(current_distributor, @customer)
  end

  protected

  def collection
    @customers = end_of_association_chain.includes(:address, :account)

    @customers = @customers.tagged_with(params[:tag]) unless params[:tag].blank?
    @customers = @distributor.customers.search(params[:query]) unless params[:query].blank?

    @customers = @customers.page(params[:page]) if params[:page]
  end
end
