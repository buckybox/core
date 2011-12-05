class Distributor::AccountsController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json

  def show
    show! do
      @transactions = @account.transactions
    end
  end
end
