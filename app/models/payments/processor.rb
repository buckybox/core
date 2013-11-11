class Payments::Processor
  attr_accessor :import_transaction_list

  def initialize(import_transaction_list)
    self.import_transaction_list = import_transaction_list
  end

  def process(attributes)
    if import_transaction_list.can_process?
      ImportTransactionList.transaction do
        processed_data = @import_transaction_list.process_import_transactions_attributes(attributes)
        @import_transaction_list.process_attributes(processed_data) #returns true if saved
      end
    else
      false
    end
  rescue => e
    @import_transaction_list.processing_failed!
    raise e
  end
end
