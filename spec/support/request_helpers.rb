module Requests
  module JsonHelpers
    def json_request method, *args
      public_send(method, *args) # send the request

      expect(response.headers["Content-Type"]).to eq "application/json; charset=utf-8"
      @json_response = JSON.parse(response.body) # will raise with invalid JSON
    end

    def json_response
      @json_response
    end
  end
end
