require "spec_helper"

describe Distributor::BoxesController do
  describe "routing" do

    it "routes to #index" do
      get("/distributor_boxes").should route_to("distributor_boxes#index")
    end

    it "routes to #new" do
      get("/distributor_boxes/new").should route_to("distributor_boxes#new")
    end

    it "routes to #show" do
      get("/distributor_boxes/1").should route_to("distributor_boxes#show", :id => "1")
    end

    it "routes to #edit" do
      get("/distributor_boxes/1/edit").should route_to("distributor_boxes#edit", :id => "1")
    end

    it "routes to #create" do
      post("/distributor_boxes").should route_to("distributor_boxes#create")
    end

    it "routes to #update" do
      put("/distributor_boxes/1").should route_to("distributor_boxes#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/distributor_boxes/1").should route_to("distributor_boxes#destroy", :id => "1")
    end

  end
end
