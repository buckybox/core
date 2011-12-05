require "spec_helper"

describe Distributor::AccountsController do
  describe "routing" do

    it "routes to #index" do
      get("/distributor_accounts").should route_to("distributor_accounts#index")
    end

    it "routes to #new" do
      get("/distributor_accounts/new").should route_to("distributor_accounts#new")
    end

    it "routes to #show" do
      get("/distributor_accounts/1").should route_to("distributor_accounts#show", :id => "1")
    end

    it "routes to #edit" do
      get("/distributor_accounts/1/edit").should route_to("distributor_accounts#edit", :id => "1")
    end

    it "routes to #create" do
      post("/distributor_accounts").should route_to("distributor_accounts#create")
    end

    it "routes to #update" do
      put("/distributor_accounts/1").should route_to("distributor_accounts#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/distributor_accounts/1").should route_to("distributor_accounts#destroy", :id => "1")
    end

  end
end
