module ApiHelpers
  def base_url
    "http://api.test.local/v1"
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
      "Webstore-ID" => api_distributor.parameter_name,
    }
  end

  shared_examples_for "an authenticated API" do |method|
    it "returns 401 with no credentials" do
      headers = {}
      json_request(method, url, nil, headers)

      expect(response.status).to eq 401
      expect(json_response).to have_key "message"
    end

    it "returns 401 with invalid credentials" do
      headers = {
        "API-Key" => "fuck",
        "API-Secret" => "off",
        "Webstore-ID" => api_distributor.parameter_name,
      }
      json_request(method, url, nil, headers)

      expect(response.status).to eq 401
      expect(json_response).to have_key "message"
    end

    it "returns 404 with master key for inexistent web stores" do
      headers = {
        "API-Key" => Figaro.env.api_master_key,
        "API-Secret" => Figaro.env.api_master_secret,
        "Webstore-ID" => "inexistent_webstore",
      }

      json_request(method, url, nil, headers)
      expect(response.status).to eq 404
      expect(json_response).to have_key "message"
    end
  end

  shared_examples_for "an unauthenticated API" do |method|
    it "does NOT return 401 with no credentials" do
      headers = {}
      json_request(method, url, nil, headers)

      expect(response.status).not_to eq 401
    end
  end
end
