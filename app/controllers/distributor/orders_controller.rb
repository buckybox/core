class Distributor::OrdersController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json

  protected

  def collection
    @orders ||= end_of_association_chain.completed
  end
end
