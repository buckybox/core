class Distributor::RoutesController < Distributor::BaseController
  belongs_to :distributor
  actions :all, except: [ :index ]

  respond_to :html, :xml, :json

  def create
    create! do |success, failure|
      success.html { redirect_to routes_distributor_settings_url}
    end
  end

  def update
    update! { routes_distributor_settings_url }
  end

  def destroy
    destroy! { routes_distributor_settings_url }
  end
end
