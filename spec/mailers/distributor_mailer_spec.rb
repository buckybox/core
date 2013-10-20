require "spec_helper"

describe DistributorMailer do
  before { @distributor = Fabricate(:distributor) }

  shared_examples_for "using GMail's SMTP" do
    it "uses GMail's SMTP server to have a low spam score" do
      expect(mail.delivery_method.settings[:address]).to eq Figaro.env.gmail_smtp_host
    end
  end

  describe "#welcome" do
    let(:mail) { DistributorMailer.welcome(@distributor) }

    it "has the right headers" do
      mail.to.should eq [@distributor.email]
      mail.subject.should eq "#{@distributor.name}, welcome to Bucky Box!"
    end

    it_behaves_like "using GMail's SMTP"
  end

  describe "#bank_setup" do
    let(:mail) { DistributorMailer.bank_setup(@distributor, "New Bank") }

    it_behaves_like "using GMail's SMTP"
  end
end

