class Api::V1::CustomersController < Api::V1::BaseController
  before_action :fetch_json_body, only: [:create, :update]

  def_param_group :address do
    # :nocov:
    param :address, Object, "Customer Address", required: true do
      param :line_1, String, required: true
      param :line_2, String
      param :suburb, String
      param :city, String
      param :postcode, String
      param :delivery_note, String
      param :mobile_phone, String
      param :home_phone, String
      param :work_phone, String
    end
    # :nocov:
  end

  def_param_group :customer do
    # :nocov:
    param :customer, Object, "JSON String ", required: true do
      param :first_name, String, "First name of the customer", required: true
      param :last_name, String, "Last name of the customer"
      param :email, String, "Customer's email address", required: true
      param_group :address
    end
    # :nocov:
  end

  api :GET, '/customers', "Get list of customers"
  param :email, String, desc: "Customer's Email Address. Returns array of single customer"
  param :embed, String, desc: "Children available: address"
  example "/customers/?email=will@buckybox.com&embed=address"
  def index
    @customers = if params[:email].nil?
      @distributor.customers
    else
      @distributor.customers.where(email: params[:email])
    end
  end

  api :POST, '/customers/sign_in'
  param :email, String, desc: "TODO"
  param :password, String, desc: "TODO"
  param :embed, String, desc: "Children available: address"
  def sign_in
    unless params[:email] && params[:password]
      return unprocessable_entity "Missing email or password"
    end

    @customers = []
    current_customer = @distributor.customers.find_by(email: params[:email])

    if current_customer.present? && current_customer.valid_password?(params[:password])
      @customers = Customer.where(email: params[:email]).sort_by do |customer|
        customer.id == current_customer.id ? 1 : 0 # make sure the current customer is first
      end
    end

    if @customers.empty?
      details = params.dup
      details[:password_hash] = Digest::SHA1.hexdigest details.delete(:password)
      CronLog.log("Login failure for #{details[:email]}", details.inspect)

      Librato.increment "bucky.customer.sign_in.failure.from_api"
      Librato.increment "bucky.customer.sign_in.failure.total"
    else
      Librato.increment "bucky.customer.sign_in.success.from_api"
      Librato.increment "bucky.customer.sign_in.success.total"
    end

    render 'api/v1/customers/index'
  end

  api :GET, '/customers/:id', "Get single customer"
  param :id, Integer, desc: "Customer ID", required: true
  param :embed, String, desc: "Children available: address"
  example "/customers/123?embed=address"
  def show
    cust_id = params[:id]
    @customer = @distributor.customers.find_by(id: cust_id)
    not_found if @customer.nil?
  end

  api :POST, '/customers', "Create a new customer"
  description 'A JSON object representing the new customer'
  param_group :customer
  example '{
      "first_name": "Will",
      "last_name": "Lau",
      "email": "will@buckybox.com",
      "delivery_service_id": 56,
      "address": {
          "address_1": "12 Bucky Lane",
          "address_2": "",
          "suburb": "Boxville",
          "city": "Wellington",
          "postcode": "007",
          "delivery_note": "Just slip it through the catflap",
          "home_phone": "01 234 5678",
          "mobile_phone": "012 345 6789",
          "work_phone": "98 765 4321"
      }
}'
  def create
    create_or_update
  end

  api :PATCH, '/customers/:id', "Update an existing customer"
  description 'A JSON object representing the customer'
  param_group :customer
  example '{
      "first_name": "Will",
      "last_name": "Lau",
      "email": "will@buckybox.com",
      "delivery_service_id": 56,
      "address": {
          "address_1": "12 Bucky Lane",
          "address_2": "",
          "suburb": "Boxville",
          "city": "Wellington",
          "postcode": "007",
          "delivery_note": "Just slip it through the catflap",
          "home_phone": "01 234 5678",
          "mobile_phone": "012 345 6789",
          "work_phone": "98 765 4321"
      }
}'
  def update
    create_or_update
  end

  private def create_or_update
    existing_customer = params[:id] ? @distributor.customers.find_by(id: params[:id]) : nil

    customer_json = @json_body || {}
    delivery_service_id = customer_json.delete("delivery_service_id")
    address_json = customer_json.delete("address")

    customer_parameters = ActionController::Parameters.new(customer_json)
    customer_attributes = customer_parameters.permit(*%i(first_name last_name email via_webstore))

    if existing_customer
      existing_customer.update_attributes(customer_attributes)
    else
      @customer = Customer.new(customer_attributes)
    end

    address_parameters = ActionController::Parameters.new(address_json)
    address_attributes = address_parameters.permit(
      *%i(address_1 address_2 suburb city postcode delivery_note home_phone mobile_phone work_phone)
    )

    if existing_customer
      existing_customer.update_attributes(address_attributes: address_attributes)
    else
      @customer.build_address(address_attributes)
    end

    unless existing_customer
      @customer.distributor_id = @distributor.id
      @customer.delivery_service = @distributor.delivery_services.find_by(id: delivery_service_id)
      @customer.number = Customer.next_number(@distributor)
    end

    @customer = existing_customer if existing_customer

    if @customer.save
      status = existing_customer ? :ok : :created
      render 'api/v1/customers/create', status: status, location: api_v1_customer_url(id: @customer.id)
    else
      unprocessable_entity @customer.errors
    end
  end
end
