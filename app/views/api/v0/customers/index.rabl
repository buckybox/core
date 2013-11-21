# app/views/api/v0/customers/index.rabl
collection @customers
attributes :id, :first_name, :last_name, :email, :delivery_service_id

unless @embed['address'].nil?
	child :address do
	  attributes :address_1, :address_2, :suburb, :city, :delivery_note, :home_phone, :mobile_phone, :post_code, :work_phone
	end
end