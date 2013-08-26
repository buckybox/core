Fabricator(:transaction) do
  transactionable { Fabricate(:payment) }
  description 'payment transaction'
  account
  amount 1000
end

Fabricator(:transaction_deduction, from: :transaction) do
  transactionable { Fabricate(:deduction) }
  description 'deduction transaction'
end

