require 'spec_helper'

describe "Distributor::Transactions" do
  describe "GET /distributor_transactions" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get distributor_transactions_path
      response.status.should be(200)
    end
  end
end
