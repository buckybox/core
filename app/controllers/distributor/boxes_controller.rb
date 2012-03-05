class Distributor::BoxesController < Distributor::ResourceController
  belongs_to :distributor
  actions :all, except: [ :index, :destroy ]

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to boxes_distributor_settings_url }
    end
  end

  def update
    update! { boxes_distributor_settings_url }
  end
end
