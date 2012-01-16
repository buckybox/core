class Distributor::PaymentsController < Distributor::BaseController
  belongs_to :distributor
  actions :create

  respond_to :html, :xml, :json

  def index 
    @payments = current_distributor.payments.order('created_at DESC')
  end

  def create
    create! do |success, failure|
      success.html { redirect_to distributor_dashboard_url }
      failure.html do
        if params[:payment][:account_id].blank?
          flash[:error] = 'Please, select an customer for this payment.'
        elsif params[:payment][:amount].to_f <= 0
          flash[:error] = 'Please, enter in a positive ammount for the payment.'
        elsif params[:payment][:description].blank?
          flash[:error] = 'Please, include a description for this payment.'
        end

        redirect_to distributor_dashboard_url
      end
    end
  end

  def process_upload
    if transactions = params['transactions']
      if /.csv/.match(transactions.original_filename)
        csv = TransactionsUploader.new
        csv.store!(transactions)
        csv.retrieve_from_store!(transactions.original_filename)
        @file = File.open(csv.path,'r')
      end
    end

    render :upload_transactions
  end

  def create_from_csv
    csv = TransactionsUploader.new
    csv.retrieve_from_store!(params['transactions_filename'])
    Payment.create_from_csv!(current_distributor, csv, params['customers'])

    redirect_to distributor_payments_path
  end
end
