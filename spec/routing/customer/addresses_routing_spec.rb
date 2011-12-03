require "spec_helper"

describe Customer::AddressesController do
  describe "routing" do

    it "routes to #index" do
      get("/customer_addresses").should route_to("customer_addresses#index")
    end

    it "routes to #new" do
      get("/customer_addresses/new").should route_to("customer_addresses#new")
    end

    it "routes to #show" do
      get("/customer_addresses/1").should route_to("customer_addresses#show", :id => "1")
    end

    it "routes to #edit" do
      get("/customer_addresses/1/edit").should route_to("customer_addresses#edit", :id => "1")
    end

    it "routes to #create" do
      post("/customer_addresses").should route_to("customer_addresses#create")
    end

    it "routes to #update" do
      put("/customer_addresses/1").should route_to("customer_addresses#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/customer_addresses/1").should route_to("customer_addresses#destroy", :id => "1")
    end

  end
end
