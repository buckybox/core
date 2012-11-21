class Distributor::CustomersController < Distributor::ResourceController
  respond_to :html, :xml, :json

  before_filter :get_form_type, only: [:edit, :update]

  def index
    if current_distributor.routes.empty?
      redirect_to distributor_settings_routes_url, alert: 'You must create a route before you can create users.' and return
    end

    index! do
      @show_tour = current_distributor.customers_index_intro
    end
  end

  def new
    new! do
      @address = @customer.build_address
      @customer.number = Customer.next_number(current_distributor)
    end
  end

  def create
    create! do |success, failure|
      success.html { redirect_to distributor_customer_url(@customer) }
    end
  end

  def edit
    edit!
  end

  def update
    update! do |success, failure|
      success.html { redirect_to distributor_customer_url(@customer) }
    end
  end

  def show
    show! do
      @address          = @customer.address
      @account          = @customer.account
      @orders           = @account.orders.active
      @deliveries       = @account.deliveries.ordered
      @transactions     = account_transactions(@account)
      @transactions     = [Transaction.dummy(0, "Opening Balance", @account.created_at)] if @transactions.empty?
      @transactions_sum = @account.calculate_balance
      @show_tour        = current_distributor.customers_show_intro
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

  def get_form_type
    @form_type = (params[:form_type].to_s == 'delivery' ? 'delivery_form' : 'personal_form')
  end

  def collection
    @customers = end_of_association_chain

    @customers = @customers.tagged_with(params[:tag]) unless params[:tag].blank?

    unless params[:query].blank?
      query = params[:query].gsub(/\./, '')
      if params[:query].to_i == 0
        @customers = current_distributor.customers.search(query)
      else
        @customers = current_distributor.customers.where(number: query.to_i)
      end
    end
    
    @customers = @customers.ordered_by_next_delivery.includes(account: {route: {}}, tags: {}, next_order: {box: {}})

  end
end
