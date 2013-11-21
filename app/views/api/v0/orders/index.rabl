# app/views/api/v0/orders/index.rabl
collection @orders
attributes :id, :box_id, :active
attribute :start => :start_date
attribute :next_occurrence => :next_date

attribute :account_id => :customer_id

node :frequency do |order|
	order.schedule_rule.frequency.to_s
end