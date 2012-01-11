Fabricator(:order) do
  box!
  account! { |order| Fabricate(:customer, :distributor => order.box.distributor).account }
  quantity 1
  frequency 'single'
end

Fabricator(:active_order, :from => :order) do
  completed true
  active true
end

