module ApiHelpers
  def base_url
    "http://api.test.dev/v0"
  end

  def distributor
    @distributor ||= Fabricate(:distributor)
    @distributor.generate_api_key!
    @distributor
  end

  def headers
    {
      "API-Key" => distributor.api_key,
      "API-Secret" => distributor.api_secret,
    }
  end

  shared_examples_for "an authenticated API" do |method|
    it "requires authentication" do
      [
        {},
        {"API-Key" => "fuck", "API-Secret" => "off"}
      ].each do |headers|
        json_request(method, url, nil, headers)

        expect(response.status).to eq 401
        expect(json_response).to have_key "message"
      end
    end
  end

end
