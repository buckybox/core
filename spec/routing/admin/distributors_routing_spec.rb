require "spec_helper"

describe Admin::DistributorsController do
  describe "routing" do

    it "delivery_services to #index" do
      get("/admin/distributors").should route_to("admin/distributors#index")
    end

    it "delivery_services to #new" do
      get("/admin/distributors/new").should route_to("admin/distributors#new")
    end

    it "delivery_services to #show" do
      get("/admin/distributors/1").should route_to("admin/distributors#show", :id => "1")
    end

    it "delivery_services to #edit" do
      get("/admin/distributors/1/edit").should route_to("admin/distributors#edit", :id => "1")
    end

    it "delivery_services to #create" do
      post("/admin/distributors").should route_to("admin/distributors#create")
    end

    it "delivery_services to #update" do
      put("/admin/distributors/1").should route_to("admin/distributors#update", :id => "1")
    end

    it "delivery_services to #destroy" do
      delete("/admin/distributors/1").should route_to("admin/distributors#destroy", :id => "1")
    end

  end
end
