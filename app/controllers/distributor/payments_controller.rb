class Distributor::PaymentsController < Distributor::BaseController
  belongs_to :distributor
  actions :create

  respond_to :html, :xml, :json

  def index 
    @payments = current_distributor.payments.bank_transfer.order('created_at DESC')
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

  def upload_transactions
    @statement = BankStatement.new
  end

  def process_upload
    @statement = BankStatement.new(params['bank_statement'])
    @statement.distributor = current_distributor
    @statement.save!
    @customer_remembers = @statement.customer_remembers
    render :upload_transactions
  end

  def create_from_csv
    @statement = BankStatement.find(params['statement_id'])
    @statement.process_statement!(params['customers'])

    redirect_to distributor_payments_path
  end
end
