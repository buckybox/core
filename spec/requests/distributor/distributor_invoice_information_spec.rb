require 'spec_helper'

describe "Distributor::InvoiceInformation" do
  describe "GET /distributor_invoice_information" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get distributor_invoice_information_index_path
      response.status.should be(200)
    end
  end
end
