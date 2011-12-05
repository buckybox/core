require "spec_helper"

describe Distributor::TransactionsController do
  describe "routing" do

    it "routes to #index" do
      get("/distributor_transactions").should route_to("distributor_transactions#index")
    end

    it "routes to #new" do
      get("/distributor_transactions/new").should route_to("distributor_transactions#new")
    end

    it "routes to #show" do
      get("/distributor_transactions/1").should route_to("distributor_transactions#show", :id => "1")
    end

    it "routes to #edit" do
      get("/distributor_transactions/1/edit").should route_to("distributor_transactions#edit", :id => "1")
    end

    it "routes to #create" do
      post("/distributor_transactions").should route_to("distributor_transactions#create")
    end

    it "routes to #update" do
      put("/distributor_transactions/1").should route_to("distributor_transactions#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/distributor_transactions/1").should route_to("distributor_transactions#destroy", :id => "1")
    end

  end
end
