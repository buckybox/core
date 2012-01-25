require "spec_helper"

describe CustomerMailer do
  before(:each) do
    @customer = Fabricate(:customer)
  end
  describe "login_details" do
    let(:mail) { CustomerMailer.login_details(@customer)}

    it "renders the headers" do
      mail.subject.should =~ /Login details/
      mail.to.should eq([@customer.email])
      mail.from.should eq(["no-reply@buckybox.com"])
    end
  end

end
