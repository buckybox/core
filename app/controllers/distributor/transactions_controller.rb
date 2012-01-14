class Distributor::TransactionsController < Distributor::BaseController
  belongs_to :distributor
  actions :create

  respond_to :html, :xml, :json
end
