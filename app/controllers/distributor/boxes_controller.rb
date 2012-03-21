class Distributor::BoxesController < Distributor::ResourceController
  actions :all, except: [ :index, :destroy ]

  respond_to :html, :xml, :json

  def create
    create! { distributor_settings_boxes_url }
  end

  def update
    update! { distributor_settings_boxes_url }
  end
end
