require 'spec_helper'

describe "distributors/show.html.haml" do
  before(:each) do
    @distributor = assign(:distributor, stub_model(Distributor,
      :name => "Name",
      :url => "Url"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Url/)
  end
end
