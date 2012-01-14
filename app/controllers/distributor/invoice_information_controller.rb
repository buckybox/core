class Distributor::InvoiceInformationController < Distributor::BaseController
  belongs_to :distributor, :singleton => true
  actions :create

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to distributor_wizard_success_url }
      failure.html { redirect_to :back }
    end
  end
end
