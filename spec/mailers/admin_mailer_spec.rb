require "spec_helper"

describe AdminMailer do
  describe "#information_email" do
    let(:options) do
      {
        to: Figaro.env.sysalerts_email,
        subject: "Data integrity tests failed [#{Rails.env}]",
        body: "Doh!",
      }
    end

    let(:mail) { AdminMailer.information_email(options) }

    it "has the right headers" do
      expect(mail.to).to eq [Figaro.env.sysalerts_email]
      expect(mail.subject).to eq "Data integrity tests failed [test]"

      [/plain/, /html/].each do |type|
        expect(mail.body.parts.find { |p| p.content_type.match(type) }.body.raw_source).to include "Doh!"
      end
    end
  end
end
