require "spec_helper"

describe DistributorsController do
  describe "routing" do

    it "routes to #index" do
      get("/distributors").should route_to("distributors#index")
    end

    it "routes to #new" do
      get("/distributors/new").should route_to("distributors#new")
    end

    it "routes to #show" do
      get("/distributors/1").should route_to("distributors#show", :id => "1")
    end

    it "routes to #edit" do
      get("/distributors/1/edit").should route_to("distributors#edit", :id => "1")
    end

    it "routes to #create" do
      post("/distributors").should route_to("distributors#create")
    end

    it "routes to #update" do
      put("/distributors/1").should route_to("distributors#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/distributors/1").should route_to("distributors#destroy", :id => "1")
    end

  end
end
