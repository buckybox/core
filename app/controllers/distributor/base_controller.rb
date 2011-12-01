class Distributor::BaseController < ApplicationController
  before_filter :authenticate_distributor!
  layout 'distributor'
end
