class Distributor::OrdersController < Distributor::BaseController
  belongs_to :distributor

  skip_before_filter :authenticate_distributor!, :only => [:create]

  respond_to :html, :xml, :json

  protected

  def collection
    @orders ||= end_of_association_chain.completed
  end
end
