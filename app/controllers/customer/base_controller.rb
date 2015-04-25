class Customer::BaseController < ApplicationController
  before_action :authenticate_customer!
  layout 'customer'

protected

  def current_customer
    super.decorate if super
  end
end
