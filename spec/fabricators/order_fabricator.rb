Fabricator(:order) do
  account!
  box! { |order| Fabricate(:box, distributor: order.account.distributor) }
  quantity 1
  frequency 'single'
  schedule { new_single_schedule }
  active true
  completed true
end

Fabricator(:active_order, from: :order) do
  completed true
  active true
end

Fabricator(:inactive_order, :from => :order) do
  active false
end

Fabricator(:recurring_order, from: :order) do
  frequency 'weekly'
  schedule { new_recurring_schedule }
end

Fabricator(:active_recurring_order, from: :recurring_order) do
  completed true
  active true
end
