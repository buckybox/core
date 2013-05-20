class Distributor::ExtrasController < Distributor::ResourceController
  actions :all, except: [ :index, :destroy ]

  respond_to :html, :xml, :json

  def create
    create! { distributor_settings_extras_url }
    usercycle.event(current_distributor, "distributor_created_extra")
  end

  def update
    update! { distributor_settings_extras_url }
  end
end
