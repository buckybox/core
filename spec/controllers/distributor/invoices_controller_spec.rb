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
end
