Fabricator(:package) do
  order
  packing_list {|attrs| Fabricate(:packing_list, distributor: attrs[:order].distributor)}
end
