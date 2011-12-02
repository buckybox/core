require "spec_helper"

describe Distributor::BanksController do
  describe "routing" do

    it "routes to #index" do
      get("/distributor_banks").should route_to("distributor_banks#index")
    end

    it "routes to #new" do
      get("/distributor_banks/new").should route_to("distributor_banks#new")
    end

    it "routes to #show" do
      get("/distributor_banks/1").should route_to("distributor_banks#show", :id => "1")
    end

    it "routes to #edit" do
      get("/distributor_banks/1/edit").should route_to("distributor_banks#edit", :id => "1")
    end

    it "routes to #create" do
      post("/distributor_banks").should route_to("distributor_banks#create")
    end

    it "routes to #update" do
      put("/distributor_banks/1").should route_to("distributor_banks#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/distributor_banks/1").should route_to("distributor_banks#destroy", :id => "1")
    end

  end
end
