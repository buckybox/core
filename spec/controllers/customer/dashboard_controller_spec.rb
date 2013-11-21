require 'spec_helper'

describe Customer::DashboardController, :js do
  before do
    @distributor = Fabricate(:distributor_with_information)
    @customer = Fabricate(:customer, distributor: distributor)
  end

  describe "GET 'index'" do
    sign_in_as_customer

    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end
end
