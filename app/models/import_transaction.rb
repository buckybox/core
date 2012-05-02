class ImportTransaction < ActiveRecord::Base

  belongs_to :import_transaction_list
  belongs_to :customer

end
