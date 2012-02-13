require 'spec_helper'

describe Distributor::InvoicesController do
  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    @customer = Fabricate(:customer, :distributor => @distributor)
    sign_in @distributor
    @invoice = Fabricate(:invoice, :account => @customer.account)
  end

  it "renders index" do
    get :index, :distributor_id => @distributor.id
    response.should be_success
    assigns(:invoices).should_not be_empty
  end

  context "to_send" do
    it "lists invoices that need invoicing" do
      pending
    end
  end

  context "do_send" do
    it "sends invoices" do
      pending
    end
  end

end
