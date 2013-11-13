class Api::V0::CustomersController < Api::V0::BaseController

	def_param_group :address do
	  param :line_1, String
	  param :line_2, String
	  param :suburb, String
	  param :city, String
	  param :postcode, String
	  param :delivery_note, String
	  param :mobile_phone, String
	  param :home_phone, String
	  param :work_phone, String
	end

	def_param_group :customer do
	  param :customer, Hash, "JSON String ", required: true do
	    param :first_name, String, "First name of the customer", required: true
	    param :last_name, String, "Last name of the customer"
	    param_group :address, required: true 
	  end
	end


	api :GET, '/v0/customers',  "Get list of customers"
	param :email , String, desc: "Customer's Email Address. Returns array of single customer"
	def index
		cust_email = params[:email]
		if cust_email.nil?
    	@customers = @distributor.customers
    else
    	@customers = @distributor.customers.find_by(email: cust_email) 
    end
  end

	api :GET, '/customers/:id',  "Get single customer"
	param :id,Integer, desc: "Customer ID", required: true  
  def show
		cust_id = params[:id]
		@customer  = @distributor.customers.find_by(id: cust_id)
		if @customer.nil?
			not_found
		end
	end

	api :POST, '/customers',  "Create a new customer"
	param_group :customer
	def create
		new_customer = request.body.read

		internal_server_error if new_customer.nil?

		new_customer = JSON.parse new_customer
		@customer = Customer.new	new_customer['customer']
		@customer.distributor_id = @distributor.id
		@customer.number = Customer.next_number(@distributor)

		if @customer.save
			render 'api/v0/customers/create', status: :created, location: api_v0_customer_url(id: @customer.id) and return
		else
			internal_server_error @customer.errors
		end
	end

end