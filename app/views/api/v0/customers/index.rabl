# app/views/api/v0/customers/index.rabl
collection @customers
attributes :id, :first_name, :last_name, :email, :address, :delivery_service_id

