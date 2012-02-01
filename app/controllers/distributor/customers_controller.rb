class Distributor::CustomersController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json

  def new
    new! do
      @address = @customer.build_address
    end
  end
end
