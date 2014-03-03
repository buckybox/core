class Customer; end # So an AR model doesn't have to be included

require_relative "../../../../app/models/customer/form/update_delivery_address"

describe Customer::Form::UpdateDeliveryAddress do

  describe "retrieving existing attributes" do
    let(:address)  { double("address", address_1: nil, address_2: nil, suburb: nil, city: nil, postcode: nil, delivery_note: nil) }
    let(:customer) { double("customer", address: address) }
    let(:form)     { Customer::Form::UpdateDeliveryAddress.new(customer: customer) }

    it "gets the first line of the address" do
      address.should_receive(:address_1) { "1 Grove Dr." }
      expect(form.address_1).to eq("1 Grove Dr.")
    end

    it "gets the second line of the address" do
      address.should_receive(:address_2) { "Apt 5" }
      expect(form.address_2).to eq("Apt 5")
    end

    it "gets the suburb" do
      address.should_receive(:suburb) { "Grandville" }
      expect(form.suburb).to eq("Grandville")
    end

    it "gets the city" do
      address.should_receive(:city) { "city" }
      expect(form.city).to eq("city")
    end

    it "gets the postcode" do
      address.should_receive(:postcode) { "73628" }
      expect(form.postcode).to eq("73628")
    end

    it "gets the delivery note" do
      address.should_receive(:delivery_note) { "Put the box by the door." }
      expect(form.delivery_note).to eq("Put the box by the door.")
    end
  end

  describe "storing new attributes" do
    let(:args) do
      {
        "address_1"     => "1 Grove Dr.",
        "address_2"     => "Apt 5",
        "suburb"        => "Grandville",
        "city"          => "city",
        "postcode"      => "73628",
        "delivery_note" => "Put the box by the door.",
      }
    end
    let(:form) { Customer::Form::UpdateDeliveryAddress.new(args) }

    it "stores a first line of the address" do
      expect(form.address_1).to eq("1 Grove Dr.")
    end

    it "stores a second line of the address" do
      expect(form.address_2).to eq("Apt 5")
    end

    it "stores a suburb" do
      expect(form.suburb).to eq("Grandville")
    end

    it "stores a city" do
      expect(form.city).to eq("city")
    end

    it "stores a postcode" do
      expect(form.postcode).to eq("73628")
    end

    it "stores a delivery note" do
      expect(form.delivery_note).to eq("Put the box by the door.")
    end
  end

  describe "saving" do
    let(:address)     { double("address") }
    let(:distributor) { double("distributor", require_address_1?: false, require_address_2?: false, require_suburb?: false, require_city?: false, require_postcode?: false, require_delivery_note?: false) }
    let(:customer)    { double("customer", distributor: distributor, address: address) }
    let(:args) do
      {
        "address_1"     => "1 Grove Dr.",
        "address_2"     => "Apt 5",
        "suburb"        => "Grandville",
        "city"          => "city",
        "postcode"      => "73628",
        "delivery_note" => "Put the box by the door.",
        "customer"      => customer,
      }
    end
    let(:form) { Customer::Form::UpdateDeliveryAddress.new(args) }

    it "saves the address attributes" do
      address_args = { address_1: "1 Grove Dr.", address_2: "Apt 5", suburb: "Grandville", city: "city", postcode: "73628", delivery_note: "Put the box by the door." }
      customer.stub(:update_attributes) { true }
      address.should_receive(:update_attributes).with(address_args)
      form.save
    end
  end

end
