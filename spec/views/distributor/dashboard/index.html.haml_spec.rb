require "spec_helper"

describe "distributor/dashboard/index.html.haml" do
  describe "accounts to invoice" do
    before(:each) do
      @notifications = []
    end
    context "with no accounts to invoice" do
      before(:each) do
        @accounts_to_invoice = []
      end
      it "displays confirmation" do
        render
        rendered.should have_content("0 invoices ready to send")
      end
    end

    context "with accounts to invoice" do
      before(:each) do
        @accounts_to_invoice = [Fabricate(:account)]
      end
      it "displays corret total for 1 invoice" do 
        render 
        rendered.should have_content("1 invoice ready to send")
      end
      it "displays corret total for 2 invoic" do 
        @accounts_to_invoice = [Fabricate(:account), Fabricate(:account)]
        render 
        rendered.should have_content("2 invoices ready to send")
      end
    end
  end
end
