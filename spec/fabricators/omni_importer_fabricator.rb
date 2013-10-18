Fabricator(:omni_importer) do
  country
  rules    <<EOY
        columns: date trans_type sort_code account_number description debt_amount credit_amount empty blank none
        DATE:
          date_parse:
            c0:
            format: '%d/%m/%Y'
        DESC:
          not_blank:
            - merge:
              - trans_type
              - sort_code
              - account_number
              - description
            - trans_type
        AMOUNT:
          not_blank:
            - negative: c5
            - c6
        options:
          - header
EOY
  
  name "UK Lloyds"
  import_transaction_list{
    ActionDispatch::Http::UploadedFile.new(
      :tempfile => File.new(Rails.root.join('spec','support','test_upload_files','transaction_imports','uk_lloyds_tsb.csv')),
      :filename => File.basename(File.new(Rails.root.join('spec','support','test_upload_files','transaction_imports','uk_lloyds_tsb.csv')))
    )
  }
end

Fabricator(:omni_importer_for_bank_deposit, from: :omni_importer) do
  payment_type "Bank Deposit"
end

Fabricator(:paypal_omni_importer, from: :omni_importer) do
  id OmniImporter::PAYPAL_ID
  payment_type "PayPal"
  country nil
end

