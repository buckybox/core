require "spec_helper"

# According to the RSpec docs you don't really need to test RESTful routes
# so this group of tests should only last as long as we have to move the
# non-RESTful routes and deal with the legacy named routes as a result. 
RSpec.describe "routes for Deliveries", type: :routing do

  describe "RESTful routes" do

    describe "create" do

      it "routes to /distributor/deliveries/new", broken_or_unused: true do
        expect(get: "/distributor/deliveries/new").to be_routable
      end

      it "routes to /distributor/deliveries" do
        expect(post: "/distributor/deliveries").to be_routable
      end

    end

    describe "read" do

      it "routes to /distributor/deliveries" do
        expect(get: "/distributor/deliveries").to be_routable
      end

      it "routes to /distributor/deliveries/2", broken_or_unused: true do
        expect(get: "/distributor/deliveries/2").to be_routable
      end

    end

    describe "update" do

      it "routes to /distributor/deliveries/2/edit", broken_or_unused: true do
        expect(get: "/distributor/deliveries/2/edit").to be_routable
      end

      it "routes to /distributor/deliveries/2" do
        expect(put: "/distributor/deliveries/2").to be_routable
      end

    end

    describe "delete" do

      it "routes to /distributor/deliveries/2" do
        expect(delete: "/distributor/deliveries/2").to be_routable
      end

    end

  end

  describe "non-RESTful routes" do

    describe "by url" do

      it "routes to /distributor/deliveries/date/2015-02-15/view/2" do
        expect(get: "/distributor/deliveries/date/2015-02-15/view/2").to route_to(controller: "distributor/deliveries", action: "index", date: "2015-02-15", view: "2")
      end

      it "routes to /distributor/deliveries/date/2015-02-15/reposition" do
        expect(post: "/distributor/deliveries/date/2015-02-15/reposition").to route_to(controller: "distributor/deliveries", action: "reposition", date: "2015-02-15")
      end

      it "routes to /distributor/deliveries/update_status" do
        expect(post: "/distributor/deliveries/update_status").to route_to(controller: "distributor/deliveries", action: "update_status")
      end

      it "routes to /distributor/deliveries/make_payment" do
        expect(post: "/distributor/deliveries/make_payment").to route_to(controller: "distributor/deliveries", action: "make_payment")
      end

      it "routes to /distributor/deliveries/master_packing_sheet" do
        expect(post: "/distributor/deliveries/master_packing_sheet").to route_to(controller: "distributor/deliveries", action: "master_packing_sheet")
      end

      it "routes to /distributor/deliveries/export" do
        expect(post: "/distributor/deliveries/export").to route_to(controller: "distributor/export/deliveries", action: "index")
      end

      it "routes to /distributor/deliveries/export_extras" do
        expect(post: "/distributor/deliveries/export_extras").to route_to(controller: "distributor/export/extras", action: "index")
      end

      it "routes to /distributor/deliveries/export_exclusions_substitutions" do
        expect(post: "/distributor/deliveries/export_exclusions_substitutions").to route_to(controller: "distributor/export/exclusions_substitutions", action: "index")
      end

    end

    describe "by named route" do

      it "has the named route date_distributor_deliveries" do
        expect(get: date_distributor_deliveries_path('2015-02-15', 2)).to route_to(controller: "distributor/deliveries", action: "index", date: "2015-02-15", view: "2")
      end

      it "has the named route reposition_distributor_deliveries" do
        expect(post: reposition_distributor_deliveries_path('2015-02-15')).to route_to(controller: "distributor/deliveries", action: "reposition", date: "2015-02-15")
      end

      it "has the named route update_status_distributor_deliveries" do
        expect(post: update_status_distributor_deliveries_path).to route_to(controller: "distributor/deliveries", action: "update_status")
      end

      it "has the named route make_payment_distributor_deliveries" do
        expect(post: make_payment_distributor_deliveries_path).to route_to(controller: "distributor/deliveries", action: "make_payment")
      end

      it "has the named route master_packing_sheet_distributor_deliveries" do
        expect(post: master_packing_sheet_distributor_deliveries_path).to route_to(controller: "distributor/deliveries", action: "master_packing_sheet")
      end

      it "has the named route export_distributor_deliveries" do
        expect(post: export_distributor_deliveries_path).to route_to(controller: "distributor/export/deliveries", action: "index")
      end

      it "has the named route export_extras_distributor_deliveries" do
        expect(post: export_extras_distributor_deliveries_path).to route_to(controller: "distributor/export/extras", action: "index")
      end

      it "has the named route export_exclusions_substitutions_distributor_deliveries" do
        expect(post: export_exclusions_substitutions_distributor_deliveries_path).to route_to(controller: "distributor/export/exclusions_substitutions", action: "index")
      end

    end

  end

end
