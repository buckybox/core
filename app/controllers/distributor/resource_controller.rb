class Distributor::ResourceController < Distributor::BaseController
  inherit_resources

  protected

  def begin_of_association_chain
    current_distributor
  end
end

