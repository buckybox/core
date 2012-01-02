require 'spec_helper'

describe Distributor::DashboardController do

  before(:each) do 
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    sign_in @distributor
    @billing_evt = Fabricate(:billing_event, :distributor => @distributor)
    @custormer_evt = Fabricate(:customer_event, :distributor => @distributor)
    @dismissed_evt = Fabricate(:customer_event, :distributor => @distributor, :dismissed => true)
  end

  context "visiting dashboard" do
    before(:each) do
      get :index
    end

    it "should render" do
      response.should render_template("index")
    end

    subject { assigns[:notifications] }
    context "listing events" do
      it "should find active events" do 
        should have(2).events
      end
    end
  end
end
