class Distributor::PaymentsController < Distributor::BaseController
  belongs_to :distributor
  actions :create

  respond_to :html, :xml, :json

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
    csv = TransactionsUploader.new
    csv.store!(params['transactions'])
    csv.retrieve_from_store!(params['transactions'].original_filename)
    Payment.load_csv!(csv)
  end
end
