require 'spec_helper'

describe "Distributor::Banks" do
  describe "GET /distributor_banks" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get distributor_banks_path
      response.status.should be(200)
    end
  end
end
