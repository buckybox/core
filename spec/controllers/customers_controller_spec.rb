require 'spec_helper'

describe CustomersController do

  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    sign_in @distributor
    @customer = Fabricate(:customer_with_account, :distributor => @distributor)
  end

  context "send_login_details" do
    before(:each) do
      get :send_login_details, :id => @customer.id
    end
    it "should send an email" do
      ActionMailer::Base.deliveries.size.should == 1
    end
    it "should reset password" do
      assigns(:customer).password.should_not == @customer.password 
    end
    it "should redirect correctly" do
      response.should redirect_to(distributor_account_path(@distributor, @customer.account))
    end
  end

end
