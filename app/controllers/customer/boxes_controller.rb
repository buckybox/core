class Customer::BoxesController < Customer::BaseController
  belongs_to :customer
  actions :show

  respond_to :html, :xml, :json
end
