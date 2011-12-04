class Distributor::BaseController < InheritedResources::Base
  before_filter :authenticate_distributor!
  layout 'distributor'
end
