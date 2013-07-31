Fabricator(:line_item) do
  distributor
  name { sequence(:name) { |i| "Line Item #{i}" } }
end
