require "geokit"

class DirectoryController < ApplicationController
  layout false

  caches_action :index, expires_in: 24.hours

  def index
    list = Distributor::Map::Directory.generate
    render locals: { list: list }
  end

end
