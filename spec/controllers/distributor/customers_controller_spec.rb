require 'spec_helper'

describe Distributor::CustomersController do
  render_views

  as_distributor
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

  context "#update" do
    before do
      @customer_2 = Fabricate(:customer, distributor: @distributor, email: "duplicate@dups.com")
    end

    it 'should show the errors' do
      put :update, id: @customer.id, customer: {email: "duplicate@dups.com"}
      assigns(:form_type).should eq('personal_form')
    end
  end
end
