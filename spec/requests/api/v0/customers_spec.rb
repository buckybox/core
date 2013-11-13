require "spec_helper"

describe "API v0" do
  describe "customers" do
    let(:api_url) { "http://api.test.dev/v0" }
    let(:headers) do
      {
        "key" => distributor.api_key, # FIXME change to "X-Key" or sth
        "secret" => distributor.api_secret, # FIXME
      }
    end

    let(:distributor) { Fabricate(:distributor) }

    before do
      distributor.generate_api_key!
    end

    describe "GET /customers" do
      before do
        @customers = Fabricate.times(2, :customer, distributor: distributor)

        get "#{api_url}/customers", nil, headers
      end

      it "returns the list of customers" do
        expect(response).to be_success
        expect(json.size).to eq @customers.size
      end
    end
  end
end
