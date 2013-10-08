class Distributor::CustomersController < Distributor::ResourceController
  respond_to :html, :xml, :json

  before_filter :check_setup, only: [:index]
  before_filter :get_form_type, only: [:edit, :update]
  before_filter :get_email_templates, only: [:index, :show]

  def index
    index! do
      @show_tour = current_distributor.customers_index_intro

      amount = @customers.map(&:account).map(&:balance).sum
      @customers_total_balance = EasyMoney.new(amount).with_currency(current_distributor.currency)
    end
  end

  def new
    new! do
      @address = @customer.build_address
    end
  end

  def create
    create! do |success, failure|
      success.html do
        tracking.event(current_distributor, "new_customer") unless current_admin.present?
        redirect_to distributor_customer_url(@customer)
      end
    end
  end

  def edit
    edit!
  end

  def update
    update! do |success, failure|
      success.html { redirect_to distributor_customer_url(@customer) }
      failure.html do
        if (phone_errors = @customer.address.errors.get(:phone_number))
          # Highlight all missing phone fields
          phone_errors.each do |error|
            PhoneCollection.attributes.each do |type|
              @customer.address.errors[type] << error
            end
          end
        end

        render get_form_type
      end
    end
  end

  def show
    show! do
      @address          = @customer.address
      @account          = @customer.account.decorate
      @orders           = @account.orders.active.decorate
      @deliveries       = @account.deliveries.ordered
      @transactions     = account_transactions(@account)
      @show_more_link   = (@transactions.size != @account.transactions.count)
      @transactions_sum = @account.calculate_balance
      @show_tour        = current_distributor.customers_show_intro
    end
  end

  def email
    super
  end

  def send_login_details
    @customer = Customer.find(params[:id])

    @customer.randomize_password
    @customer.save

    CustomerMailer.raise_errors do
      if !@customer.send_email?
        flash[:error] = "Sending emails is disabled, login details not sent"
      elsif @customer.send_login_details
        flash[:notice] = "Login details successfully sent"
      else
        flash[:error] = "Login details failed to send"
      end
    end

    tracking.event(current_distributor, "sent_login_details") unless current_admin.present?

    redirect_to distributor_customer_url(@customer)
  end

  def export
    recipient_ids = params[:export][:recipient_ids].split(',').map(&:to_i)
    csv_string    = CustomerCSV.generate(current_distributor, recipient_ids)

    tracking.event(current_distributor, "export_csv_customer_list") unless current_admin.present?

    send_csv("customer_export", csv_string)
  end

  def impersonate
    redirect_to distributor_root_path and return unless current_admin.present?

    customer = current_distributor.customers.find(params[:id])
    sign_in(customer, bypass: true) # bypass means it won't update last logged in stats

    redirect_to customer_root_path
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

      tracking.event(current_distributor, "search_customer_list") unless current_admin.present?
    end

    @customers = @customers.ordered_by_next_delivery.includes(account: {delivery_service: {}}, tags: {}, next_order: {box: {}})
  end

private

  def error message
    render json: { message: message }, status: :unprocessable_entity
  end

end
