require "spec_helper"

include ApiHelpers

describe "API v0" do
  describe "delivery services" do
    shared_examples_for "a delivery service" do
      it "returns the expected attributes" do
        expect(json_delivery_service.keys).to match_array model_attributes
      end
    end

    before do
      @delivery_services ||= Fabricate.times(2, :delivery_service, distributor: distributor)
    end

    let(:model_attributes) { %w(id name) }

    describe "GET /delivery_services" do
      let(:url) { "#{base_url}/delivery_services" }
      let(:json_delivery_service) { json_response.first["delivery_service"] }

      before do
        json_request :get, url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API", :get
      it_behaves_like "a delivery service"

      it "returns the list of delivery services" do
        expect(json_response.size).to eq @delivery_services.size
      end
    end
  end
end


