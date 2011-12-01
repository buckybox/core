require 'spec_helper'

describe "distributors/edit.html.haml" do
  before(:each) do
    @distributor = assign(:distributor, stub_model(Distributor,
      :name => "MyString",
      :url => "MyString"
    ))
  end

  it "renders the edit distributor form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributors_path(@distributor), :method => "post" do
      assert_select "input#distributor_name", :name => "distributor[name]"
      assert_select "input#distributor_url", :name => "distributor[url]"
    end
  end
end
