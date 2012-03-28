class Distributor::DistributorsController < Distributor::ResourceController
  actions :update

  respond_to :html, :xml, :json

  def update
    update! { distributor_settings_business_information_url }
  end

  protected

  def resource
    current_distributor
  end

  def begin_of_association_chain
    nil
  end
end
