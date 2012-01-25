class Customer::BaseController < InheritedResources::Base
  before_filter :authenticate_customer!
  layout 'customer'
end
