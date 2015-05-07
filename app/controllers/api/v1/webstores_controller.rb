class Api::V1::WebstoresController < Api::V1::BaseController
  api :GET, '/webstore', "Returns the current webstore settings"
  example '/v1/webstore'
  def show
    @webstore = @distributor
  end
end
