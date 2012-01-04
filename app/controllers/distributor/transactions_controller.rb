class Distributor::TransactionsController < Distributor::BaseController
  belongs_to :distributor
  respond_to :html, :xml, :json

  def update
    update! { distributor_account_path(current_distributor, @transaction.account)}
  end

  def destroy
    destroy! { distributor_account_path(current_distributor, @transaction.account) }
  end
end
