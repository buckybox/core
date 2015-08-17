require "spec_helper"

describe DistributorMailer do
  before { @distributor = Fabricate(:distributor) }

  describe "#welcome" do
    let(:mail) { DistributorMailer.welcome(@distributor) }

    it "has the right headers" do
      expect(mail.to).to eq [@distributor.email]
      expect(mail.subject).to eq "#{@distributor.name}, welcome to Bucky Box!"
    end
  end

  describe "#bank_setup" do
    let(:mail) { DistributorMailer.bank_setup(@distributor, "New Bank") }

    it "has the right headers" do
      expect(mail.to).to eq [@distributor.email]
    end
  end
end
