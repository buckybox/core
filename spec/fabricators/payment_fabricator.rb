Fabricator(:payment) do
  distributor nil
  customer nil
  amount_cents 1
  currency "MyString"
  kind "MyString"
  description "MyText"
end
