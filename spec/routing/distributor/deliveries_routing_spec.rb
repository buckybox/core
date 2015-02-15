require "spec_helper"

RSpec.describe "routes for Deliveries", :type => :routing do

  describe "RESTful routes" do

    it "routes to /distributor/deliveries" do
      expect(get: "/distributor/deliveries").to be_routable
    end

    it "routes to /distributor/deliveries" do
      expect(post: "/distributor/deliveries").to be_routable
    end

    it "routes to /distributor/deliveries/new" do
      expect(get: "/distributor/deliveries/new").to be_routable
    end

    it "routes to /distributor/deliveries/2/edit" do
      expect(get: "/distributor/deliveries/2/edit").to be_routable
    end

    it "routes to /distributor/deliveries/2" do
      expect(get: "/distributor/deliveries/2").to be_routable
    end

    it "routes to /distributor/deliveries/2" do
      expect(put: "/distributor/deliveries/2").to be_routable
    end

    it "routes to /distributor/deliveries/2" do
      expect(delete: "/distributor/deliveries/2").to be_routable
    end

  end

  describe "non-RESTful routes" do

    it "routes to /distributor/deliveries/date/2015-02-15/view/2" do
      expect(get: "/distributor/deliveries/date/2015-02-15/view/2").to be_routable
    end

    it "routes to /distributor/deliveries/date/2015-02-15/reposition" do
      expect(post: "/distributor/deliveries/date/2015-02-15/reposition").to be_routable
    end

    it "routes to /distributor/deliveries/update_status" do
      expect(post: "/distributor/deliveries/update_status").to be_routable
    end

    it "routes to /distributor/deliveries/make_payment" do
      expect(post: "/distributor/deliveries/make_payment").to be_routable
    end

    it "routes to /distributor/deliveries/master_packing_sheet" do
      expect(post: "/distributor/deliveries/master_packing_sheet").to be_routable
    end

    it "routes to /distributor/deliveries/export" do
      expect(post: "/distributor/deliveries/export").to be_routable
    end

    it "routes to /distributor/deliveries/export_extras" do
      expect(post: "/distributor/deliveries/export_extras").to be_routable
    end

    it "routes to /distributor/deliveries/export_exclusions_substitutions" do
      expect(post: "/distributor/deliveries/export_exclusions_substitutions").to be_routable
    end

  end

end
