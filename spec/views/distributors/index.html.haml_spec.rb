require 'spec_helper'

describe "distributors/index.html.haml" do
  before(:each) do
    assign(:distributors, [
      stub_model(Distributor,
        :name => "Name",
        :url => "Url"
      ),
      stub_model(Distributor,
        :name => "Name",
        :url => "Url"
      )
    ])
  end

  it "renders a list of distributors" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Url".to_s, :count => 2
  end
end
