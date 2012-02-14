require 'spec_helper'

describe Customer::DashboardController do
  before do
    @customer = Fabricate(:customer)
    sign_in @customer
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end
end
