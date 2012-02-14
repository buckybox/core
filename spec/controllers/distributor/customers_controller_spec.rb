require 'spec_helper'

describe Distributor::CustomersController do
  render_views

  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    sign_in @distributor
    @customer = Fabricate(:customer, distributor: @distributor)
  end

  context "send_login_details" do
    before(:each) do
      get :send_login_details, id: @customer.id
    end

    it "should send an email" do
      ActionMailer::Base.deliveries.size.should == 1
    end

    it "should reset password" do
      assigns(:customer).password.should_not == @customer.password 
    end

    it "should redirect correctly" do
      response.should redirect_to(distributor_customer_path(@distributor, @customer))
    end
  end
end
