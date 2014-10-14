module ApiHelpers
  def base_url
    "http://api.test.dev/v1"
  end

  def api_distributor
    @distributor ||= Fabricate(:distributor)
    @distributor.generate_api_key!
    @distributor
  end

  def headers
    {
      "API-Key" => api_distributor.api_key,
      "API-Secret" => api_distributor.api_secret,
    }
  end

  shared_examples_for "an authenticated API" do |method|
    it "returns 401 with no credentials" do
      headers = {}
      json_request(method, url, nil, headers)

      expect(response.status).to eq 401
      expect(json_response).to have_key "message"
    end

    it "returns 404 with invalid credentials" do
      headers = {"API-Key" => "fuck", "API-Secret" => "off"}
      json_request(method, url, nil, headers)

      expect(response.status).to eq 404
      expect(json_response).to have_key "message"
    end
  end
end
