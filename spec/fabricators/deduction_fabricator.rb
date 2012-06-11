Fabricator(:deduction) do
  distributor nil
  account nil
  amount_cents 1
  currency "MyString"
  kind "MyString"
  description "MyText"
  reversed false
  reversed_at "2012-06-11 13:58:41"
  transaction_id 1
  reversal_transaction_id 1
  source "MyString"
  deductable_id 1
  deductable_type "MyString"
end
