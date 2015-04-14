require "spec_helper"

describe Admin::DistributorsController do
  describe "routing" do
    it "delivery_services to #index" do
      expect(get("/admin/distributors")).to route_to("admin/distributors#index")
    end

    it "delivery_services to #new" do
      expect(get("/admin/distributors/new")).to route_to("admin/distributors#new")
    end

    it "delivery_services to #edit" do
      expect(get("/admin/distributors/1/edit")).to route_to("admin/distributors#edit", :id => "1")
    end

    it "delivery_services to #create" do
      expect(post("/admin/distributors")).to route_to("admin/distributors#create")
    end

    it "delivery_services to #update" do
      expect(put("/admin/distributors/1")).to route_to("admin/distributors#update", :id => "1")
    end
  end
end
