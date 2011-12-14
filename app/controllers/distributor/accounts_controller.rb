class Distributor::AccountsController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json

  def show
    show! do
      @transactions = @account.transactions
    end
  end

  def update
    @distributor = Distributor.find(params[:distributor_id])
    @account = Account.find(params[:id])
    @account.change_balance_to(params[:account][:balance])
    params[:account].delete(:balance)

    update! do |success, failure|
      success.html { redirect_to [current_distributor, @account] }
      failure.html { render action: 'edit' }
    end
  end

  protected

  def collection
    @accounts = end_of_association_chain.includes(:customer => :address)

    unless params[:query].blank?
      customers = @distributor.customers.search(params[:query])
      @accounts = @accounts.where(:customer_id => customers.map(&:id))
    end

    @accounts = @accounts.page(params[:page]) if params[:page]
  end
end
