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
	  param :customer, Hash do
	    param :first_name, String, "First name of the customer"
	    param :last_name, String, "Last name of the customer"
	    param_group :address
	  end
	end


	api :GET, '/customers',  "Get list of customers"
	param :email , String, desc: "Customer's Email Address. Returns array of single customer" , required: false
	def index
		cust_email = params[:email]
		if cust_email.nil?
    	@customers = @distributor.customers
    else
    	@customers = @distributor.customers.find_by(email: cust_email) 
    end
  end

	api :GET, '/customers/:id',  "Get single customer"
	param :id, Fixnum, desc: "Customer ID", required: true  
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
		new_customer = params[:customer]
		new_customer = JSON.parse new_customer
		binding.pry
=begin
		@customer = Customer.new(	
															email: cust_email, 
															first_name: cust_fname, 
															last_name: cust_lname, 
															delivery_service_id: delivery_service_id
														)
		
		@customer.address = Address.new( params )

		if @customer.save
			@customer
		else
			internal_server_error customer.errors
		end
=end
	end

end