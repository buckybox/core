Fabricator(:bank_information) do
  distributor!
  name 'Bank Name'
  account_name 'Account Name'
  account_number 1
  customer_message 'Message'
  bsb_number 1
end
