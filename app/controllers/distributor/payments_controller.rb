class Distributor::PaymentsController < Distributor::ResourceController
  actions :create

  respond_to :html, :xml, :json

  def index 
    @payments = current_distributor.payments.bank_transfer.order('created_at DESC')
    @statement = BankStatement.new
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

  def process_upload
    @kiwibank = Bucky::TransactionImports::Kiwibank.new
    @kiwibank.import(params['bank_statement']["statement_file"].path)
    unless @kiwibank.valid?
      return render :index
    end
    @transaction_list = @kiwibank.transactions_for_display(current_distributor)
    render :upload_transactions
  end

  def create_from_csv
    @statement = BankStatement.find(params['statement_id'])
    @statement.process_statement!(params['customers'])

    redirect_to distributor_payments_url
  end
end
