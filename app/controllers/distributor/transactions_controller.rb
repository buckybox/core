class Distributor::TransactionsController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json
end
