class Distributor::PaymentsController < Distributor::ResourceController
  actions :create

  respond_to :html, :xml, :json

  before_filter :load_import_transaction_list, only: [:process_payments, :show]

  def index 
    @import_transaction_list = current_distributor.import_transaction_lists.new
    @show_tour = current_distributor.payments_index_intro
    @selected_omni_importer = current_distributor.last_used_omni_importer
    load_index
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

    render :index
  end

  def create
    create! do |success, failure|
      success.html { redirect_to distributor_dashboard_url }

      failure.html do
        if params[:payment][:account_id].blank?
          flash[:error] = 'Please, select a customer for this payment.'
        elsif params[:payment][:amount].to_f <= 0
          flash[:error] = 'Please, enter in a positive amount for the payment.'
        elsif params[:payment][:description].blank?
          flash[:error] = 'Please, include a description for this payment.'
        end
        redirect_to distributor_dashboard_url
      end
    end
  end

  def process_payments
    processed_data = @import_transaction_list.process_import_transactions_attributes(params[:import_transaction_list])

    if @import_transaction_list.process_attributes(processed_data)
      redirect_to distributor_payments_url, notice: "Payments processed successfully"
    else
      flash.now[:alert] = "There was a problem"
      render :match_payments
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
    @import_transaction_lists = current_distributor.import_transaction_lists.draft
  end

  def load_import_transaction_list
    @import_transaction_list = current_distributor.import_transaction_lists.find(params[:id])
  end
end
