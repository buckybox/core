class Distributor::InvoiceInformationController < Distributor::ResourceController
  defaults singleton: true
  actions :create, :update

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to distributor_settings_invoice_information_url, notice: 'Invoice information was successfully created.' }
      failure.html { render 'distributor/settings/invoice_information' }
    end
  end

  def update
    update! do |success, failure|
      success.html { redirect_to distributor_settings_invoice_information_url, notice: 'Invoice information was successfully updated.' }
      failure.html { render 'distributor/settings/invoice_information' }
    end
  end
end
