class Api::V1::WebstoresController < Api::V1::BaseController
  skip_before_action :authenticate, only: :index

  def index
    @webstores = Distributor.active_webstore.joins(:localised_address).active
  end

  api :GET, '/webstore', "Returns the current webstore settings"
  example '/v1/webstore'
  def show
    @webstore = @distributor
    @company_logo = @webstore.company_logo.banner.url.present? ? [fqdn, view_context.image_path(@webstore.company_logo.banner.url)].join : nil
    @company_team_image = @webstore.company_team_image.photo.url.present? ? [fqdn, view_context.image_path(@webstore.company_team_image.photo.url)].join : nil
  end

private

  def fqdn
    ["//", Figaro.env.host, ":", Figaro.env.port].join.chomp(":")
  end
end
