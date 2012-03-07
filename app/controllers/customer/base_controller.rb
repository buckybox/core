class Customer::BaseController < ApplicationController
  before_filter :authenticate_customer!
  layout 'customer'
end
