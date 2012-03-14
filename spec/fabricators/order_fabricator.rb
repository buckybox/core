Fabricator(:order) do
  box!
  account! { |order| Fabricate(:customer, :distributor => order.box.distributor).account }
  quantity 1
  frequency 'single'
  schedule { Bucky::Schedule.new(new_single_schedule) }
end

Fabricator(:active_order, :from => :order) do
  completed true
  active true
end

Fabricator(:recurring_order, :from => :order) do
  frequency 'weekly'
  schedule { Bucky::Schedule.new(new_recurring_schedule) }
end
