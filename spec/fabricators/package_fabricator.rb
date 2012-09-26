Fabricator(:package) do
  order!
  packing_list! {|package| Fabricate(:packing_list, distributor: package.order.distributor)}
end
