Fabricator(:order) do
  box!
  account! { |order| Fabricate(:customer_with_account, :distributor => order.box.distributor).account }
  quantity 1
  frequency 'single'
  schedule { new_single_schedule }
end

Fabricator(:active_order, :from => :order) do
  completed true
  active true
end

Fabricator(:recurring_order, :from => :order) do
  frequency 'weekly'
  schedule { new_recurring_schedule }
end
