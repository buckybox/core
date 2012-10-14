Fabricator(:order) do
  account!
  box! { |order| Fabricate(:box, distributor: order.account.distributor) }
  schedule_rule!
  quantity 1
  completed true
end

Fabricator(:active_order, from: :order) do
  completed true
  active true
end

Fabricator(:inactive_order, from: :order) do
  active false
end

Fabricator(:recurring_order, from: :order) do
  schedule_rule! { new_recurring_schedule }
end

Fabricator(:recurring_order_everyday, from: :order) do
  schedule_rule! { new_everyday_schedule }
end

Fabricator(:active_recurring_order, from: :recurring_order) do
  completed true
  active true
end
