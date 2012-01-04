class Distributor::TransactionsController < Distributor::BaseController
  belongs_to :distributor
  actions :create

  def update
    update! { distributor_account_path(@transaction.account) }
  end

  def create
    create! { distributor_account_path(@transaction.account) }
  end
  respond_to :html, :xml, :json
end
