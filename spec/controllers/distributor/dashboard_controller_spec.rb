require 'spec_helper'

describe Distributor::DashboardController do
  render_views

  as_distributor

  before do
    @billing_evt   = Fabricate(:billing_event,  distributor: @distributor)
    @custormer_evt = Fabricate(:customer_event, distributor: @distributor)
    @dismissed_evt = Fabricate(:customer_event, distributor: @distributor, dismissed: true)
    Account.stub(:need_invoicing).and_return([Fabricate(:account)])
    Fabricate(:payment, :distributor => @distributor, :source => 'manual')
  end

  context 'visiting dashboard' do
    before { get :index }

    specify { response.should render_template('index') }

    context "listing events" do
      specify { assigns[:events].should have(2).events }
    end
  end
end
