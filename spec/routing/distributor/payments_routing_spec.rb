require "spec_helper"

describe Distributor::PaymentsController do
  describe "routing" do

    it "routes to #index" do
      get("/distributor_payments").should route_to("distributor_payments#index")
    end

    it "routes to #new" do
      get("/distributor_payments/new").should route_to("distributor_payments#new")
    end

    it "routes to #show" do
      get("/distributor_payments/1").should route_to("distributor_payments#show", :id => "1")
    end

    it "routes to #edit" do
      get("/distributor_payments/1/edit").should route_to("distributor_payments#edit", :id => "1")
    end

    it "routes to #create" do
      post("/distributor_payments").should route_to("distributor_payments#create")
    end

    it "routes to #update" do
      put("/distributor_payments/1").should route_to("distributor_payments#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/distributor_payments/1").should route_to("distributor_payments#destroy", :id => "1")
    end

  end
end
