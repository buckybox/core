class Distributor::InvoiceInformationController < Distributor::BaseController
  belongs_to :distributor, :singleton => true
  actions :create, :update

  respond_to :html, :xml, :json

  def create
    create! notice: "Bank Info was successfully created." do |success, failure|
      success.html { redirect_to bank_info_distributor_settings_url(current_distributor) }
      failure.html { render 'distributor/settings/bank_info' }
    end
  end

  def update
    update! notice: "Bank Info was successfully updated." do |success, failure|
      success.html { redirect_to bank_info_distributor_settings_url(current_distributor) }
      failure.html { render 'distributor/settings/bank_info' }
    end
  end
end
