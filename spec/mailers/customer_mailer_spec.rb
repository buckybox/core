require "spec_helper"

describe CustomerMailer do
  before { @customer = Fabricate(:customer) }
  let(:body) { mail.body.encoded }

  describe "#login_details" do
    let(:mail) { CustomerMailer.login_details(@customer)}

    it "renders the headers" do
      expect(mail.subject).to include "login details"
      expect(mail.from).to eq [Figaro.env.no_reply_email]
      expect(mail.reply_to).to eq [@customer.distributor.support_email]
      expect(mail.to).to eq [@customer.email]
      expect(mail.header["X-Mailer"].value).to eq(Figaro.env.x_mailer)
    end
  end

  describe "#halt" do
    let(:mail){ CustomerMailer.orders_halted(@customer) }

    it "cc's distributor" do
      expect(mail.cc).to eq [@customer.distributor.support_email]
    end
  end

  describe "#email_template" do
    let(:email_template) {
      Fabricate.build(:email_template)
    }
    let(:mail) { CustomerMailer.email_template(@customer, email_template) }

    specify { expect(mail.to).to eq [@customer.email] }
    specify { expect(mail.subject).to eq email_template.subject }
    specify { expect(mail.body.parts.find{|p| p.content_type.match(/plain/)}.body.raw_source).to eq(email_template.body)}
  end

  describe "#order_confirmation" do
    let(:order) { Fabricate(:order, customer: @customer) }
    let(:mail) { CustomerMailer.order_confirmation(order) }

    specify { expect(mail.to).to eq [order.customer.email] }
    specify { expect(mail.cc).to be_empty }

    it "cc's distributor if enabled" do
      allow(order.distributor).to receive(:email_distributor_on_new_webstore_order) { true }

      expect(mail.cc).to eq [order.distributor.support_email]
    end

    it "includes the present phone numbers" do
      # ugly way to stub the decorated customer
      decorated_customer = order.customer.decorate
      decorated_customer.stub(mobile_phone: "MOB", work_phone: "WORK")
      allow(order.customer).to receive(:decorate) { decorated_customer }

      expect(body).to include "Mobile Phone", "MOB"
      expect(body).to include "Work Phone", "WORK"
      expect(body).not_to include "Home Phone"
    end

    it "includes line items if present" do
      allow(order).to receive(:exclusions_string) { "EXC" }

      expect(body).to include "Exclusions", "EXC"
      expect(body).not_to include "Substitutes"
    end

    it "includes the schedule rule" do
      expect(body).to include "Deliver weekly", "starting"
    end

    context "when the delivery service is not a pickup point" do
      specify { expect(body).to include "Delivery Address:" }
      specify { expect(body).to include @customer.name }
      specify { expect(body).to include @customer.address.join("<br/>") }
    end
  end
end
