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
    
    it "should find events" do 
      assigns[:notifications].should have(2).events
    end

    it "should not find dismissed events" do 
      pending
      assigns[:notifications].should have(2).events
    end
  end
end
