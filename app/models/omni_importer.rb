class OmniImporter < ActiveRecord::Base
  attr_accessible :all, :country_id, :import_transaction_list, :name, :rules

  mount_uploader :import_transaction_list, ImportTransactionListUploader

  belongs_to :country

  def file_format
    'omni_importer'
  end
end
