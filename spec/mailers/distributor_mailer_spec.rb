require "spec_helper"

describe DistributorMailer do
  before { @distributor = Fabricate(:distributor) }

  describe "#welcome" do
    let(:mail) { DistributorMailer.welcome(@distributor) }

    it "has the right headers" do
      mail.to.should eq [@distributor.email]
      mail.subject.should eq "#{@distributor.name}, welcome to Bucky Box!"
    end
  end

  describe "#bank_setup" do
    let(:mail) { DistributorMailer.bank_setup(@distributor, "New Bank") }

    it "uses GMail's SMTP server to have a low spam score" do
      expect(mail.delivery_method.settings[:address]).to eq Figaro.env.gmail_smtp_host
    end
  end
end

