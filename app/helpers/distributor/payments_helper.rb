module Distributor::PaymentsHelper

  def show_draft_import_transaction_list(import_transaction, import_transaction_lists)
    return [] if import_transaction.blank?
    @already_shown ||= []

    result = if @last_import_transaction.blank? || @last_import_transaction.transaction_date != import_transaction.transaction_date
               show_now = import_transaction_lists.select{|tl| tl.import_transactions.ordered.first.transaction_date >= import_transaction.transaction_date && !@already_shown.include?(tl) rescue false}
               @already_shown = (@already_shown + show_now).uniq
               show_now
             else
               []
             end
    @last_import_transaction = import_transaction
    result.compact
  end
end
