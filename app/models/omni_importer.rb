class OmniImporter < ActiveRecord::Base
  attr_accessible :global, :country_id, :import_transaction_list, :name, :rules, :remove_import_transaction_list, :import_transaction_list_cache

  mount_uploader :import_transaction_list, ImportTransactionListUploader

  belongs_to :country

  def file_format
    'omni_importer'
  end

  def rows
    @rows ||= CSV.parse(import_transaction_list.read)
  rescue StandardError => ex
    errors.add(:import_transaction_list, ex.message)
  end
end
