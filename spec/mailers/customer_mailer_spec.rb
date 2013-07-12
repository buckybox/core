require "spec_helper"

describe CustomerMailer do
  before { @customer = Fabricate(:customer) }

  describe "login_details" do
    let(:mail) { CustomerMailer.login_details(@customer)}

    it "renders the headers" do
      mail.subject.should include "login details"
      mail.from.should eq [@customer.distributor.support_email]
      mail.to.should eq [@customer.email]
    end
  end

  describe "halt" do
    let(:mail){ CustomerMailer.orders_halted(@customer) }

    it "cc's distributor" do
      mail.cc.should eq [@customer.distributor.support_email]
    end
  end

  describe "email_template" do
    let(:email_template) {
      Fabricate.build(:email_template)
    }
    let(:mail) { CustomerMailer.email_template(@customer, email_template) }

    specify { mail.to.should eq [@customer.email] }
    specify { mail.subject.should eq email_template.subject }
    specify { mail.body.parts.find{|p| p.content_type.match(/plain/)}.body.raw_source.should eq(email_template.body)}
  end
end
