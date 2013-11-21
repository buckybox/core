require "spec_helper"

include ApiHelpers

describe "API v0" do
  describe "boxes" do
    shared_examples_for "a box" do
      it "returns the expected attributes" do
        expect(json_box.keys).to match_array model_attributes
      end

      it "returns embedable attributes" do
        json_request :get, "#{url}?embed=#{embedable_attributes.join(',')}", nil, headers

        expect(response).to be_success
        expect(json_box.keys).to match_array(model_attributes | embedable_attributes)
      end

      describe "box_items" do
        it "returns the expected attributes" do
          json_request :get, "#{url}?embed=box_items", nil, headers

          expect(json_box["box_items"].keys).to match_array %w(id name)
        end
      end
    end

    before do
      @boxes ||= Fabricate.times(2, :box, distributor: distributor)
    end

    let(:model_attributes) { %w(id name description price_cents) }
    let(:embedable_attributes) { %w(images box_items extras extras_limit exclusion_limit substitute_limit) }

    describe "GET /boxes" do
      let(:url) { "#{base_url}/boxes" }
      let(:json_box) { json_response.first["box"] }

      before do
        json_request :get, url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API", :get
      it_behaves_like "a box"

      it "returns the list of boxes" do
        expect(json_response.size).to eq @boxes.size
      end
    end

    describe "GET /boxes/:id" do
      let(:url) { "#{base_url}/boxes/#{box.id}" }
      let(:box) { @boxes.first }
      let(:json_box) { json_response["box"] }

      before do
        json_request :get, url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API", :get
      it_behaves_like "a box"

      it "returns the box" do
        expect(json_response.size).to eq 1
        expect(json_response["box"]["id"]).to eq box.id
      end

      context "with a unknown ID" do
        before { json_request :get, "#{url}0000", nil, headers }
        specify { expect(response).to be_not_found }
      end

      context "with a box of another distributor" do
        before do
          distributor = Fabricate(:distributor)
          box = Fabricate(:box, distributor: distributor)
          json_request :get, "#{base_url}/boxes/#{box.id}", nil, headers
        end

        specify { expect(response).to be_not_found }
      end
    end
  end
end

