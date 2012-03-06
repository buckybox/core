class Distributor::BankInformationController < Distributor::BaseController
  belongs_to :distributor, :singleton => true
  actions :create, :update

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to bank_info_distributor_settings_url(@distributor) }
      failure.html { render 'distributor/settings/bank_info' }
    end
  end
  
  def update
    update! do |success, failure|
      success.html { redirect_to bank_info_distributor_settings_url(@distributor) }
      failure.html { render 'distributor/settings/bank_info' }
    end
  end
end
