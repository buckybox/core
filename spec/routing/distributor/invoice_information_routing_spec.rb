require "spec_helper"

describe Distributor::InvoiceInformationController do
  describe "routing" do

    it "routes to #index" do
      get("/distributor_invoice_information").should route_to("distributor_invoice_information#index")
    end

    it "routes to #new" do
      get("/distributor_invoice_information/new").should route_to("distributor_invoice_information#new")
    end

    it "routes to #show" do
      get("/distributor_invoice_information/1").should route_to("distributor_invoice_information#show", :id => "1")
    end

    it "routes to #edit" do
      get("/distributor_invoice_information/1/edit").should route_to("distributor_invoice_information#edit", :id => "1")
    end

    it "routes to #create" do
      post("/distributor_invoice_information").should route_to("distributor_invoice_information#create")
    end

    it "routes to #update" do
      put("/distributor_invoice_information/1").should route_to("distributor_invoice_information#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/distributor_invoice_information/1").should route_to("distributor_invoice_information#destroy", :id => "1")
    end

  end
end
