class Api::V0::WebstoresController < Api::V0::BaseController
  api :GET, '/webstore', "Returns the current webstore settings"
  example '/v0/webstore'
  def show
    @webstore = @distributor
  end
end

