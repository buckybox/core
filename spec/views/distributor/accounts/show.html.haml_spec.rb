require 'spec_helper'

describe "distributor_accounts/show.html.haml" do
  before(:each) do
    @account = assign(:account, stub_model(Distributor::Account,
      :distributor => nil,
      :customer => nil,
      :balance_cents => 1,
      :currenty => "Currenty"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Currenty/)
  end
end
