# app/views/api/v0/orders/show.rabl
object @order
attributes :id, :box_id, :created_at, :updated_at, :active

node :customer_id do
	@customer_id
end  
