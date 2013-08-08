class Customer::BaseController < ApplicationController
  before_filter :authenticate_customer!
  layout 'customer'

protected

  def current_customer
    super.decorate if super
  end
end
