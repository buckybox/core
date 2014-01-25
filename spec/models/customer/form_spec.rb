class Customer; end # So an AR model doesn't have to be included

require_relative "../../../app/models/customer/form"

describe Customer::Form do

  describe "attributes" do
    let(:customer) { double("customer", id: 1, address: "1 St", distributor: double("distributor")) }
    let(:form)     { Customer::Form.new(customer: customer) }

    it "has a customer" do
      expect(form.customer).to eq(customer)
    end

    it "has an id" do
      expect(form.id).to eq(customer.id)
    end

    it "has an address" do
      expect(form.address).to eq(customer.address)
    end

    it "has a distributor" do
      expect(form.distributor).to eq(customer.distributor)
    end
  end

  it "returns that the form data has already been persisted" do
    form = Customer::Form.new
    expect(form.persisted?).to be_true
  end

end
