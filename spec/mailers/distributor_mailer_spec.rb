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
end

