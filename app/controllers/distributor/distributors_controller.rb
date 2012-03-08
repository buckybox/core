class Distributor::DistributorsController < Distributor::ResourceController
  actions :update

  respond_to :html, :xml, :json

  def update
    update! do |success, failure|
      success.html { redirect_to distributor_settings_business_info_url }
      failure.html { render template: 'distributor/settings/business_info' }
    end
  end
end
