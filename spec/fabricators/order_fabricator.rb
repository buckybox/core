Fabricator(:order) do
  box!
  account! { |order| Fabricate(:customer, :distributor => order.box.distributor).account }
  quantity 1
  frequency 'single'
  schedule { new_single_schedule }
  active true
  completed true
end

Fabricator(:inactive_order, :from => :order) do
  active false
end

Fabricator(:recurring_order, :from => :order) do
  frequency 'weekly'
  schedule { new_recurring_schedule }
end
