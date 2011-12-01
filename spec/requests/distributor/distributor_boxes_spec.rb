require 'spec_helper'

describe "Distributor::Boxes" do
  describe "GET /distributor_boxes" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get distributor_boxes_path
      response.status.should be(200)
    end
  end
end
