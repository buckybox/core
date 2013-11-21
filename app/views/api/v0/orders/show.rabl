# app/views/api/v0/orders/show.rabl
object @order
attributes :id, :box_id, :active
attribute :start => :start_date
attribute :next_occurrence => :next_date

node :customer_id do
	@customer_id
end  

node :frequency do |order|
	order.schedule_rule.frequency.to_s
end