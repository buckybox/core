class Distributor::InvoiceInformationController < Distributor::ResourceController
  actions :create, :update

  respond_to :html, :xml, :json

  def create
    create! notice: "Invoicing Info was successfully created." do |success, failure|
      success.html { redirect_to distributor_settings_invoicing_info_url }
      failure.html { render 'distributor/settings/invoicing_info' }
    end
  end

  def update
    update! notice: "Invoicing Info was successfully updated." do |success, failure|
      success.html { redirect_to distributor_settings_invoicing_info_url }
      failure.html { render 'distributor/settings/invoicing_info' }
    end
  end
end
