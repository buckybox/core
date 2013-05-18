class Distributor::DistributorsController < Distributor::ResourceController
  actions :update

  respond_to :html, :xml, :json

  def update
    update! do |success, failure|
      success.html { redirect_to distributor_settings_business_information_url, notice: 'Business information was successfully created.' }
      failure.html { render 'distributor/settings/business_information' }
    end
  end

  protected

  def resource
    current_distributor
  end

  def begin_of_association_chain
    nil
  end
end
