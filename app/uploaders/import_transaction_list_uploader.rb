# encoding: utf-8

class ImportTransactionListUploader < CarrierWave::Uploader::Base

  storage :file

  def store_dir
    "system/uploads/payments/csv/#{model.file_format}"
  end
  
  def extension_white_list
    %w(csv)
  end

  def filename
     "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end
end
