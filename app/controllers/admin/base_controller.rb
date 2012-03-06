class Admin::BaseController < InheritedResources::Base
  before_filter :authenticate_admin!
  layout 'admin'
end
