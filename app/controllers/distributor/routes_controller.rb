class Distributor::RoutesController < Distributor::ResourceController
  actions :all, except: [:index, :destroy]

  respond_to :html, :xml, :json

  def create
    create! { distributor_settings_routes_url }
    usercycle.event(current_distributor, 'distributor_created_route')
  end

  def update
    update! { distributor_settings_routes_url }
  end
end
