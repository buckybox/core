class DistributorsController < InheritedResources::Base
  respond_to :html, :xml, :json

  #TODO: this looks like it is missing authentication to me - jbv
  def update
    update! do |success, failure|
      success.html { redirect_to distributor_wizard_boxes_url }
      failure.html { redirect_to :back }
    end
  end
end
