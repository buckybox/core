class Distributor::ImportTransactionsController < Distributor::ResourceController
  
  def update
    @import_transaction = current_distributor.import_transactions.find(params[:import_transaction][:id])
    @import_transaction.update_attributes(ImportTransaction.process_attributes(params[:import_transaction]))
  end
end
