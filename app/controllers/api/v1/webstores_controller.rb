class Api::V1::WebstoresController < Api::V1::BaseController
  skip_before_action :authenticate, only: :index

  def index
    @webstores = Distributor.active_webstore.joins(:localised_address).active
  end

  api :GET, '/webstore', "Returns the current webstore settings"
  example '/v1/webstore'
  def show
    @webstore = @distributor
  end
end
