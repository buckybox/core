class Distributor::CustomersController < Distributor::ResourceController
  respond_to :html, :xml, :json

  def index
    if current_distributor.routes.empty?
      redirect_to distributor_settings_routes_url, alert: 'You must create a route before you can create users.' and return
    end

    index!
  end

  def new
    new! do
      @address = @customer.build_address
      @customer.number = Customer.next_number(current_distributor)
    end
  end

  def create
    create! { distributor_customer_url(@customer) }
  end

  def update
    update! { distributor_customer_url(@customer) }
  end

  def show
    show! do
      @address      = @customer.address
      @account      = @customer.account
      @transactions = @account.transactions
      @orders       = @account.orders.active
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

    redirect_to distributor_customer_url(@customer)
  end

  protected

  def collection
    @customers = end_of_association_chain.includes(:address, :account)

    @customers = @customers.tagged_with(params[:tag]) unless params[:tag].blank?

    unless params[:query].blank?

      if params[:query].to_i == 0
        @customers = current_distributor.customers.search(params[:query])
      else
        @customers = current_distributor.customers.where(number: params[:query].to_i)
      end
    end

    @customers = @customers.page(params[:page]) if params[:page]
  end
end
