# encoding: utf-8

class ImportTransactionListUploader < CarrierWave::Uploader::Base

  storage :file

  def store_dir
    path = "#{Rails.root}/private_uploads/payments/csv/#{model.file_format}"
    path << "/#{model.omni_importer.name.parameterize}" if model.try(:omni_importer).try(:name).try(:parameterize).present?
    path << "/#{model.distributor_id}" if model.distributor_id.present?
  end
  
  def extension_white_list
    %w(csv)
  end

  def filename
     "#{secure_token}-#{original_filename_without_format}.#{file.extension}" if original_filename.present?
  end

  def original_filename_without_format
    original_filename.gsub(/\.csv$/, '')
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end
end
