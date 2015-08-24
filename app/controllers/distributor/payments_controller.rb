class Distributor::PaymentsController < Distributor::BaseController
  before_action :check_setup, only: :index

  def index
    @import_transaction_list = current_distributor.import_transaction_lists.new
    @show_tour = current_distributor.payments_index_intro
    @selected_omni_importer = current_distributor.last_used_omni_importer
    load_index

    render :index, locals: { distributor: current_distributor.decorate }
  end

  def match_payments
    @import_transaction_list = current_distributor.import_transaction_lists.build(params[:import_transaction_list])

    if @import_transaction_list.save
      @import_transaction_list = current_distributor.import_transaction_lists.new
      @selected_omni_importer = current_distributor.last_used_omni_importer
    else
      @selected_omni_importer = current_distributor.last_used_omni_importer(@import_transaction_list.omni_importer)
    end

    load_index

    tracking.event(current_distributor, "payment_csv_uploaded") unless current_admin.present?

    render :index, locals: { distributor: current_distributor.decorate }
  end

  def process_payments
    @import_transaction_list = current_distributor.import_transaction_lists.find(params[:id])
    processor = Payments::Processor.new(@import_transaction_list)

    if processor.process(params[:import_transaction_list])
      tracking.event(current_distributor, "payment_csv_commited") unless current_admin.present?
      redirect_to distributor_payments_url, notice: "Payments processed successfully"
    else
      redirect_to distributor_payments_url, alert: "There was a problem"
    end
  end

  def destroy
    @import_transaction = current_distributor.import_transactions.find(params[:id])

    if @import_transaction.removed? || @import_transaction.remove!
      render :destroy
    end
  end

private

  def load_index
    @import_transactions = current_distributor.import_transactions.processed.not_removed.not_duplicate.ordered.limit(50).includes(:customer)
    @import_transaction_lists = current_distributor.import_transaction_lists.draft.select do |itl|
      if itl.import_transactions.empty?
        itl.destroy
        flash.now[:error] = "Could not find any valid transactions in that file."
        false
      else
        true
      end
    end
  end
end
