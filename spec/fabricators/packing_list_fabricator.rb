Fabricator(:packing_list) do
  distributor!
  date Date.today - 1.day
end
