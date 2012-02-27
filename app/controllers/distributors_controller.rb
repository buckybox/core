class DistributorsController < Distributor::BaseController
  before_filter :authenticate_distributor! # just to add some sort of authentication

  respond_to :html, :xml, :json

  #TODO: this looks like it is missing authentication to me - jbv
  def update
    update! do |success, failure|
      success.html { redirect_to contact_info_distributor_settings_url(@distributor) }
      failure.html { render template: 'distributor/settings/contact_info' }
    end
  end
end
