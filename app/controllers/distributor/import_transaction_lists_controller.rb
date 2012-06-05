class Distributor::ImportTransactionListsController < Distributor::ResourceController

  def destroy
    @import_transaction_list = current_distributor.import_transaction_lists.draft.find(params[:id])
    @import_transaction_list.destroy
    flash[:notice] = "Upload was successfully canceled."
    redirect_to distributor_payments_path
  end
end
