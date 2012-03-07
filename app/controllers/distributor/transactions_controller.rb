class Distributor::TransactionsController < Distributor::ResourceController
  actions :create, :index

  respond_to :html, :xml, :json

  def index
    @transactions = current_distributor.transactions.order("created_at desc")
  end
end
