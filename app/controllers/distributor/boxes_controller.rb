class Distributor::BoxesController < InheritedResources::Base
  belongs_to :distributor

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to distributor_wizard_boxes_url }
      failure.html { redirect_to :back }
    end
  end
end
