class Distributor::TransactionsController < Distributor::BaseController
  actions :create, :index

  belongs_to :distributor
  respond_to :html, :xml, :json

  def index
    @transactions = current_distributor.transactions.order("created_at desc")
  end
end
