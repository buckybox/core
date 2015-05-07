require "spec_helper"

include ApiHelpers

describe "API v1" do
  describe "delivery services" do
    shared_examples_for "a delivery service" do
      it "returns the expected attributes" do
        expect(json_delivery_service.keys).to match_array model_attributes
      end
    end

    before do
      @delivery_services ||= Fabricate.times(2, :delivery_service, distributor: api_distributor)
    end

    let(:model_attributes) { %w(id cache_key name fee instructions dates_grid fri mon name_days_and_fee pickup_point sat start_dates sun thu tue wed) }

    describe "GET /delivery_services" do
      let(:url) { "#{base_url}/delivery_services" }
      let(:json_delivery_service) { json_response.first }

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

    describe "GET /delivery_services/:id" do
      let(:url) { "#{base_url}/delivery_services/#{delivery_service.id}" }
      let(:delivery_service) { @delivery_services.first }
      let(:json_delivery_service) { json_response }

      before do
        json_request :get, url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API", :get
      it_behaves_like "a delivery service"

      it "returns the delivery service" do
        expect(json_response["id"]).to eq delivery_service.id
      end

      context "with a unknown ID" do
        before { json_request :get, "#{url}0000", nil, headers }
        specify { expect(response).to be_not_found }
      end

      context "with a delivery service of another distributor" do
        before do
          new_distributor = Fabricate(:distributor)
          delivery_service = Fabricate(:delivery_service, distributor: new_distributor)
          json_request :get, "#{base_url}/delivery_services/#{delivery_service.id}", nil, headers
        end

        specify { expect(response).to be_not_found }
      end
    end
  end
end
