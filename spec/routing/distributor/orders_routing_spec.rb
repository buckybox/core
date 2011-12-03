require "spec_helper"

describe Distributor::OrdersController do
  describe "routing" do

    it "routes to #index" do
      get("/distributor_orders").should route_to("distributor_orders#index")
    end

    it "routes to #new" do
      get("/distributor_orders/new").should route_to("distributor_orders#new")
    end

    it "routes to #show" do
      get("/distributor_orders/1").should route_to("distributor_orders#show", :id => "1")
    end

    it "routes to #edit" do
      get("/distributor_orders/1/edit").should route_to("distributor_orders#edit", :id => "1")
    end

    it "routes to #create" do
      post("/distributor_orders").should route_to("distributor_orders#create")
    end

    it "routes to #update" do
      put("/distributor_orders/1").should route_to("distributor_orders#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/distributor_orders/1").should route_to("distributor_orders#destroy", :id => "1")
    end

  end
end
