class Customer; end # So an AR model doesn't have to be included

require_relative "../../../../app/models/customer/form/update_password"

describe Customer::Form::UpdatePassword do
  describe "storing new attributes" do
    let(:args) do
      {
        "password"              => "cluedo",
        "password_confirmation" => "cluedo",
      }
    end
    let(:form) { Customer::Form::UpdatePassword.new(args) }

    it "stores a new password" do
      expect(form.password).to eq("cluedo")
    end

    it "stores a new password confirmation" do
      expect(form.password_confirmation).to eq("cluedo")
    end
  end

  describe "saving" do
    let(:address)     { double("address") }
    let(:distributor) { double("distributor") }
    let(:customer)    { double("customer", distributor: distributor, address: address) }
    let(:args) do
      {
        "password"              => "cluedo",
        "password_confirmation" => "cluedo",
        "customer"              => customer,
      }
    end
    let(:form) { Customer::Form::UpdatePassword.new(args) }

    it "save the customer password" do
      customer_args = { password: "cluedo", password_confirmation: "cluedo" }
      expect(customer).to receive(:update_attributes).with(customer_args)
      form.save
    end
  end
end
