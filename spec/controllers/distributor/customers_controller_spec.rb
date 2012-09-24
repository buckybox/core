require 'spec_helper'

describe Distributor::CustomersController do
  render_views

  as_distributor
  context :with_customer do
    before { @customer = Fabricate(:customer, distributor: @distributor) }

    context "send_login_details" do
      before { get :send_login_details, id: @customer.id }

      it "should send an email" do
        ActionMailer::Base.deliveries.size.should == 1
      end

      it "should reset password" do
        assigns(:customer).password.should_not == @customer.password
      end

      it "should redirect correctly" do
        response.should redirect_to(distributor_customer_path(@customer))
      end
    end
  end

  context "performance" do
    before do
      30.times do
        c = Fabricate(:customer, distributor: @distributor)
        Fabricate(:order, account: c.account)
      end
    end

    it "should not take long to load customer index" do
      expect {
        get :index
      }.to take_less_than(0.05).seconds
    end
  end
end
