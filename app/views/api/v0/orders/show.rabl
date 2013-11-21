# app/views/api/v0/orders/show.rabl
object @order
attributes :id, :box_id, :active, :start, :next_occurrence

node :customer_id do
	@customer_id
end  

node :frequency do |order|
	order.schedule_rule.frequency.to_s
end