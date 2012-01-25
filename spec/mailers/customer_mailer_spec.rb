require "spec_helper"

describe CustomerMailer do
  describe "login_details" do
    let(:mail) { CustomerMailer.login_details }

    it "renders the headers" do
      mail.subject.should eq("Login details")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

end
