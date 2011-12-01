require 'spec_helper'

describe "distributors/new.html.haml" do
  before(:each) do
    assign(:distributor, stub_model(Distributor,
      :name => "MyString",
      :url => "MyString"
    ).as_new_record)
  end

  it "renders new distributor form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => distributors_path, :method => "post" do
      assert_select "input#distributor_name", :name => "distributor[name]"
      assert_select "input#distributor_url", :name => "distributor[url]"
    end
  end
end
