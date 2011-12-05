Fabricator(:transaction) do
  distributor nil
  customer nil
  transactionable nil
  amount_cents 1
  currency "MyString"
  description "MyText"
end
