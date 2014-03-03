class Customer; end # So an AR model doesn't have to be included

require_relative "../../../../app/models/customer/form/update_contact_details"

describe Customer::Form::UpdateContactDetails do

  describe "retrieving existing attributes" do
    let(:address)  { double("address", mobile_phone: nil, home_phone: nil, work_phone: nil) }
    let(:customer) { double("customer", name: nil, email: nil, address: address) }
    let(:form)     { Customer::Form::UpdateContactDetails.new(customer: customer) }

    it "gets the customer name" do
      customer.should_receive(:name) { "Sam Davis" }
      expect(form.name).to eq("Sam Davis")
    end

    it "gets the email address" do
      customer.should_receive(:email) { "customer@email.com" }
      expect(form.email).to eq("customer@email.com")
    end

    it "gets the mobile phone" do
      address.should_receive(:mobile_phone) { "111-111-1111" }
      expect(form.mobile_phone).to eq("111-111-1111")
    end

    it "gets the home phone" do
      address.should_receive(:home_phone) { "111-111-1111" }
      expect(form.home_phone).to eq("111-111-1111")
    end

    it "gets the work phone" do
      address.should_receive(:work_phone) { "111-111-1111" }
      expect(form.work_phone).to eq("111-111-1111")
    end
  end

  describe "storing new attributes" do
    let(:args) do
      {
        "name"         => "name",
        "email"        => "customer@email.com",
        "mobile_phone" => "111-111-1111",
        "home_phone"   => "111-111-1111",
        "work_phone"   => "111-111-1111",
      }
    end
    let(:form) { Customer::Form::UpdateContactDetails.new(args) }

    it "stores a new customer name" do
      expect(form.name).to eq("name")
    end

    it "stores a new email address" do
      expect(form.email).to eq("customer@email.com")
    end

    it "stores a mobile phone" do
      expect(form.mobile_phone).to eq("111-111-1111")
    end

    it "stores a home phone" do
      expect(form.home_phone).to eq("111-111-1111")
    end

    it "stores a work phone" do
      expect(form.work_phone).to eq("111-111-1111")
    end
  end

  describe "saving" do
    let(:address)     { double("address") }
    let(:distributor) { double("distributor", require_phone?: false, collect_phone?: false) }
    let(:customer)    { double("customer", distributor: distributor, address: address) }
    let(:args) do
      {
        "name"         => "name",
        "email"        => "customer@email.com",
        "mobile_phone" => "111-111-1111",
        "home_phone"   => "111-111-1111",
        "work_phone"   => "111-111-1111",
        "customer"     => customer,
      }
    end
    let(:form) { Customer::Form::UpdateContactDetails.new(args) }

    it "saves the customer attributes" do
      customer_args = { first_name: args["name"], last_name: nil, email: args["email"] }
      customer.should_receive(:update_attributes).with(customer_args)
      form.save
    end

    it "saves the address attributes" do
      address_args = { mobile_phone: args["mobile_phone"], home_phone: args["home_phone"], work_phone: args["work_phone"] }
      customer.stub(:update_attributes) { true }
      address.should_receive(:update_attributes).with(address_args)
      form.save
    end
  end

end
