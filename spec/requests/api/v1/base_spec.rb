require "spec_helper"

include ApiHelpers

describe "API v1" do
  describe "GET /ping" do
    let(:url) { "#{base_url}/ping" }

    it "pongs!" do
      get url

      expect(response.code).to eq "200"
      expect(response.body).to eq "Pong!"
    end
  end

  describe "POST /csp-report" do
    let(:url) { "#{base_url}/csp-report" }
    let(:csp_report) {
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
    }

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
  end
end
