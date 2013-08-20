class Distributor::RoutesController < Distributor::ResourceController
  actions :all, except: [:index, :destroy]

  respond_to :html, :xml, :json

  def create
    create! { distributor_settings_routes_url }
    tracking.event(current_distributor, 'new_route') unless current_admin.present?
  end

  def update
    update! { distributor_settings_routes_url }
  end
end
