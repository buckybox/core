class Distributor::InvoiceInformationController < Distributor::BaseController
  belongs_to :distributor, :singleton => true
  actions :create, :update

  respond_to :html, :xml, :json

  def create
    create! notice: "Invoicing Info was successfully created." do |success, failure|
      success.html { redirect_to invoicing_info_distributor_settings_url(current_distributor) }
      failure.html { render 'distributor/settings/invoicing_info' }
    end
  end

  def update
    update! notice: "Invoicing Info was successfully updated." do |success, failure|
      success.html { redirect_to invoicing_info_distributor_settings_url(current_distributor) }
      failure.html { render 'distributor/settings/invoicing_info' }
    end
  end
end
