module Requests
  module JsonHelpers
    def json_request(method, *args)
      public_send(method, *args) # send the request

      no_content = response.code == "204"

      expected_content_type = no_content ? nil : "application/json; charset=utf-8"
      expect(response.headers["Content-Type"]).to eq expected_content_type

      # JSON.parse will raise with invalid JSON
      @json_response = JSON.parse(response.body) unless no_content
    end

    attr_reader :json_response
  end
end
