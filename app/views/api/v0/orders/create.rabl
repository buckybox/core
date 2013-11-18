# app/views/api/v0/orders/create.rabl
object @order
attributes :id, :box_id, :active

node :customer_id do
	@customer_id
end  