class Distributor::TransactionsController < Distributor::BaseController
  actions :create

  belongs_to :distributor

  respond_to :html, :xml, :json
end
