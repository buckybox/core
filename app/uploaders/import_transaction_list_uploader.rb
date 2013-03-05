# encoding: utf-8

class ImportTransactionListUploader < CarrierWave::Uploader::Base

  storage :file

  def store_dir
    "system/uploads/payments/csv/#{model.file_format}"
  end
  
  def extension_white_list
    %w(csv)
  end
end
