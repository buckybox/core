Fabricator(:credit_card_transaction) do
  amount         1
  success        false
  reference      "MyString"
  message        "MyString"
  action         "MyString"
  params         "MyText"
  test           false
  distributor_id 1
  account_id     1
end
