Fabricator(:order) do
  box!
  account! { |order| Fabricate(:customer, :distributor => order.box.distributor).account }
  quantity 1
  frequency 'single'
  schedule { BuckySchedule.new(new_single_schedule) }
end

Fabricator(:active_order, :from => :order) do
  completed true
  active true
end

Fabricator(:recurring_order, :from => :order) do
  frequency 'weekly'
  schedule { BuckySchedule.new(new_recurring_schedule) }
end
