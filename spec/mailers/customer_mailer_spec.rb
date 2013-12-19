require "spec_helper"

describe CustomerMailer do
  before { @customer = Fabricate(:customer) }

  describe "#login_details" do
    let(:mail) { CustomerMailer.login_details(@customer)}

    it "renders the headers" do
      mail.subject.should include "login details"
      mail.from.should eq [@customer.distributor.support_email]
      mail.to.should eq [@customer.email]
      mail.header["X-Mailer"].value.should eq(Figaro.env.x_mailer)
    end
  end

  describe "#halt" do
    let(:mail){ CustomerMailer.orders_halted(@customer) }

    it "cc's distributor" do
      mail.cc.should eq [@customer.distributor.support_email]
    end
  end

  describe "#email_template" do
    let(:email_template) {
      Fabricate.build(:email_template)
    }
    let(:mail) { CustomerMailer.email_template(@customer, email_template) }

    specify { mail.to.should eq [@customer.email] }
    specify { mail.subject.should eq email_template.subject }
    specify { mail.body.parts.find{|p| p.content_type.match(/plain/)}.body.raw_source.should eq(email_template.body)}
  end

  describe "#order_confirmation" do
    let(:customer) { Fabricate(:customer) }
    let(:order) { Fabricate(:order, customer: customer) }
    let(:mail) { CustomerMailer.order_confirmation(order) }

    specify { expect(mail.to).to eq [order.customer.email] }
    specify { expect(mail.cc).to be_empty }

    it "cc's distributor if enabled" do
      order.distributor.stub(:email_distributor_on_new_webstore_order) { true }

      expect(mail.cc).to eq [order.distributor.support_email]
    end

    it "includes the present phone numbers" do
      # ugly way to stub the decorated customer
      decorated_customer = order.customer.decorate
      decorated_customer.stub(mobile_phone: "MOB", work_phone: "WORK")
      order.customer.stub(:decorate) { decorated_customer }

      expect(mail.body.encoded).to include "Mobile Phone", "MOB"
      expect(mail.body.encoded).to include "Work Phone", "WORK"
      expect(mail.body.encoded).not_to include "Home Phone"
    end

    it "includes line items if present" do
      order.stub(:exclusions_string) { "EXC" }

      expect(mail.body.encoded).to include "Exclusions", "EXC"
      expect(mail.body.encoded).not_to include "Substitutes"
    end

    it "includes the schedule rule" do
      expect(mail.body.encoded).to include "Deliver weekly", "starting"
    end
  end
end
