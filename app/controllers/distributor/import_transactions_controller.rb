class Distributor::ImportTransactionsController < Distributor::ResourceController
  
  def update
    @import_transaction = current_distributor.import_transactions.find(params[:import_transaction][:id])
    @import_transaction.update_attributes(ImportTransaction.process_attributes(params[:import_transaction]))
  end

  def load_more_rows
    import_transactions_arel = current_distributor.import_transactions.processed.not_removed.not_duplicate.ordered
    @import_transaction = current_distributor.import_transactions.find(params[:id])
    @import_transactions = import_transactions_arel.limit(50).where(["import_transactions.transaction_date < :transaction_date OR import_transactions.transaction_date = :transaction_date AND import_transactions.created_at < :created_at", {transaction_date: @import_transaction.transaction_date, created_at: @import_transaction.created_at}])
    if @import_transactions.present?
      start_date = @import_transactions.first.transaction_date
      end_date = @import_transactions.last.transaction_date
      @import_transaction_lists = current_distributor.import_transaction_lists.draft.select("import_transaction_lists.id").joins(:import_transactions).group("import_transaction_lists.id").having(["max(import_transactions.transaction_date) > ?", end_date]).order("max(import_transactions.transaction_date)")
    else
      @import_transaction_lists = []
    end
    @last_row_reached = @import_transactions.blank? || @import_transactions.last == import_transactions_arel.last
    if @last_row_reached
      @import_transaction_lists = current_distributor.import_transaction_lists.draft.select("import_transaction_lists.id").joins(:import_transactions).group("import_transaction_lists.id").having(["max(import_transactions.transaction_date) < ?", @import_transaction.transaction_date]).order("max(import_transactions.transaction_date)")
    end
  end
end
