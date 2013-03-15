Fabricator(:import_transaction_list) do
  distributor
  draft false
  account_type 1
  omni_importer
  csv_file {
    ActionDispatch::Http::UploadedFile.new(
      :tempfile => File.new(Rails.root.join('spec','support','test_upload_files','transaction_imports','uk_lloyds_tsb.csv')),
      :filename => File.basename(File.new(Rails.root.join('spec','support','test_upload_files','transaction_imports','uk_lloyds_tsb.csv')))
    )
  }
end
