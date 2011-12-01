require "spec_helper"

describe Distributor::RoutesController do
  describe "routing" do

    it "routes to #index" do
      get("/distributor_routes").should route_to("distributor_routes#index")
    end

    it "routes to #new" do
      get("/distributor_routes/new").should route_to("distributor_routes#new")
    end

    it "routes to #show" do
      get("/distributor_routes/1").should route_to("distributor_routes#show", :id => "1")
    end

    it "routes to #edit" do
      get("/distributor_routes/1/edit").should route_to("distributor_routes#edit", :id => "1")
    end

    it "routes to #create" do
      post("/distributor_routes").should route_to("distributor_routes#create")
    end

    it "routes to #update" do
      put("/distributor_routes/1").should route_to("distributor_routes#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/distributor_routes/1").should route_to("distributor_routes#destroy", :id => "1")
    end

  end
end
