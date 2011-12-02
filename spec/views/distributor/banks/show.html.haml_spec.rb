require 'spec_helper'

describe "distributor_banks/show.html.haml" do
  before(:each) do
    @bank = assign(:bank, stub_model(Distributor::Bank,
      :distributor => nil,
      :name => "Name",
      :account_name => "Account Name",
      :account_number => "Account Number",
      :customer_message => "Customer Message"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Account Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Account Number/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Customer Message/)
  end
end
