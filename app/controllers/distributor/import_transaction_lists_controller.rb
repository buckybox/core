class Distributor::ImportTransactionListsController < Distributor::ResourceController

  def destroy
    @import_transaction_list = current_distributor.import_transaction_lists.draft.where(id: params[:id]).first
    @import_transaction_list.destroy if @import_transaction_list
    flash[:notice] = "Upload was successfully cancelled."
    redirect_to distributor_payments_path
  end
end
