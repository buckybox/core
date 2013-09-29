Fabricator(:transaction) do
  transactionable { Fabricate(:payment) }
  description 'payment transaction'
  account
  amount 10
end

Fabricator(:transaction_deduction, from: :transaction) do
  transactionable { Fabricate(:deduction) }
  description 'deduction transaction'
end

