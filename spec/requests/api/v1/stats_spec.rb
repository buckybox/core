require "spec_helper"

include ApiHelpers

describe "API v1" do
  describe "stats" do
    describe "GET /conversion-pipeline" do
      let(:url) { "#{base_url}/conversion-pipeline?from=2010-01-01" }

      before do
        Fabricate.times(2, :distributor, created_at: Time.now, last_seen_at: Time.now)
      end

      it "returns some JSON" do
        json_request :get, url, nil, headers

        expect(response).to be_success
        expect(json_response.size).to eq 8
        expect(json_response["total"]).to eq Distributor.count
      end
    end
  end
end
