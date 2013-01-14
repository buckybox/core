include ActionDispatch::TestProcess

Fabricator(:bank_statement) do
  distributor
  statement_file {
    ActionDispatch::Http::UploadedFile.new(
      :tempfile => File.new(Rails.root.join('spec','support','test_upload_files','bnz-statement.csv')),
      :filename => File.basename(File.new(Rails.root.join('spec','support','test_upload_files','bnz-statement.csv')))
    )
  }
end
