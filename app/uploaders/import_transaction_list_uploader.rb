# encoding: utf-8

class ImportTransactionListUploader < CarrierWave::Uploader::Base

  storage :file

  def store_dir
    "#{Rails.root}/private_uploads/payments/csv/#{model.file_format}"
  end
  
  def extension_white_list
    %w(csv)
  end

  def filename
    if original_filename.present?
      path = ""
      path << param_name
      path << distributor_id
      path << "/#{secure_token}-#{original_filename_without_format}.#{file.extension}"
      path
    else
      nil
    end
  end

  def param_name
    if try(model, :omni_importer, :name, :parameterize).present?
      "/#{model.omni_importer.name.parameterize}"
    else
      ''
    end
  end

  def distributor_id
    if try(model, :distributor_id).present?
      "/#{model.distributor_id}" 
    else
      ''
    end
  end

  def try(model, *args)
    return '' if model.blank?
    return model if args.blank?
    return try(model.send(args.first), *args[1..-1]) if model.respond_to?(args.first)
    ''
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
