# app/views/api/v0/orders/create.rabl
object @order
attributes :id, :box_id, :active, :extras_one_off

node :extras do
  @extras
end

node :exclusions do |order|
  order.excluded_line_item_ids
end

node :substitutes do |order|
  order.substituted_line_item_ids
end

node :customer_id do
  @customer_id
end

node :frequency do |order|
  order.schedule_rule.frequency.to_s
end
