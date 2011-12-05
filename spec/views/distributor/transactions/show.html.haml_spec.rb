require 'spec_helper'

describe "distributor_transactions/show.html.haml" do
  before(:each) do
    @transaction = assign(:transaction, stub_model(Distributor::Transaction,
      :distributor => nil,
      :customer => nil,
      :transactionable => nil,
      :amount_cents => 1,
      :currency => "Currency",
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
    rendered.should match(//)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Currency/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/MyText/)
  end
end
