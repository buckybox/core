class Distributor::BoxesController < Distributor::ResourceController
  actions :all, except: [ :index, :destroy ]

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to distributor_settings_boxes_url }
    end
  end

  def update
    update! { distributor_settings_boxes_url }
  end
end
