include ActionDispatch::TestProcess

Fabricator(:bank_statement) do
  distributor!
  statement_file fixture_file_upload('spec/support/test_upload_files/bnz-statement.csv', 'application/csv')
end
