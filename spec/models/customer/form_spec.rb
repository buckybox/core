class Customer; end

require_relative "../../../app/models/customer/form.rb"

describe Customer::Form do

  let(:form) { Customer::Form.new }

  it "returns that the form data has already been persisted" do
    expect(form.persisted?).to be_true
  end

end
