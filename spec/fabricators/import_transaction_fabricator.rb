Fabricator(:import_transaction) do
  customer
  import_transaction_list
  transaction_date "2012-05-01"
  amount_cents 1
  removed false
  description "MyText"
  match ImportTransaction::MATCH_UNABLE_TO_MATCH
end
