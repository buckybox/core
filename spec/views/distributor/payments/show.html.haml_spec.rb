require 'spec_helper'

describe "distributor_payments/show.html.haml" do
  before(:each) do
    @payment = assign(:payment, stub_model(Distributor::Payment,
      :distributor => nil,
      :customer => nil,
      :amount_cents => 1,
      :currency => "Currency",
      :kind => "Kind",
      :description => "MyText"
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
    rendered.should match(/Currency/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Kind/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/MyText/)
  end
end
