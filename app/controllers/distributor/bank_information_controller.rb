class Distributor::BankInformationController < Distributor::ResourceController
  defaults singleton: true
  actions :create, :update

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { 
        Bucky::Tracking.instance.event(current_distributor, "new_bank_information")
        redirect_to distributor_settings_bank_information_url, notice: 'Bank information was successfully created.'
      }
      failure.html { render 'distributor/settings/bank_information' }
    end
  end

  def update
    update! do |success, failure|
      success.html {
        Bucky::Tracking.instance.event(current_distributor, "new_bank_information")
        redirect_to distributor_settings_bank_information_url, notice: 'Bank information was successfully updated.'
      }
      failure.html { render 'distributor/settings/bank_information' }
    end
  end
end
