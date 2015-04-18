object @order

attributes :id, :box_id, :extras_one_off

node :extras do @extras; end

node :customer_id do |order| order.customer.id; end

node :frequency do |order| order.schedule_rule.frequency.to_s; end
node :week_days do |order| order.schedule_rule.days_as_indexes; end
node :start_date do |order| order.schedule_rule.start; end

node :exclusions do |order| order.excluded_line_item_ids; end
node :substitutions do |order| order.substituted_line_item_ids; end

