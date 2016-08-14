require "spec_helper"

include ApiHelpers

describe "API v1" do
  describe "GET /ping" do
    let(:url) { "#{base_url}/ping" }

    it_behaves_like "an unauthenticated API", :get

    it "pongs!" do
      get url

      expect(response.code).to eq "204"
      expect(response.body).to be_empty
    end
  end

  describe "POST /csp-report" do
    let(:url) { "#{base_url}/csp-report" }
    let(:csp_report) do
      <<-JSON
{
  "csp-report": {
    "document-uri": "http://example.org/page.html",
    "referrer": "http://evil.example.com/haxor.html",
    "blocked-uri": "http://evil.example.com/image.png",
    "violated-directive": "default-src 'self'",
    "effective-directive": "img-src",
    "original-policy": "default-src 'self'; report-uri http://example.org/csp-report.cgi"
  }
}
      JSON
    end

    it_behaves_like "an unauthenticated API", :post

    it "processes the report successfully" do
      expect(Bugsnag).to receive(:notify)

      post url, csp_report

      expect(response.code).to eq "204"
      expect(response.body).to be_empty
    end

    it "ignores reports from malwares" do
      expect(Bugsnag).not_to receive(:notify)

      post url, '{..."blocked-uri":"https://nikkomsgchannel...}'
    end

    it "ignores reports from IE/Edge" do
      expect(Bugsnag).not_to receive(:notify)

      post url, csp_report, {
        "HTTP_USER_AGENT" => "Mozilla/5.0 (Windows Phone 10.0; Android 4.2.1; Microsoft; Lumia 550) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Mobile Safari/537.36 Edge/13.10586",
      }
    end
  end
end
