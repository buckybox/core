class Distributor::BankInformationController < Distributor::ResourceController
  actions :create, :update

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to distributor_settings_bank_info_url }
      failure.html { render 'distributor/settings/bank_info' }
    end
  end

  def update
    update! do |success, failure|
      success.html { redirect_to distributor_settings_bank_info_url }
      failure.html { render 'distributor/settings/bank_info' }
    end
  end
end
