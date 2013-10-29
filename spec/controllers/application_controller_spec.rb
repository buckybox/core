require 'spec_helper'

describe ApplicationController do
  let(:time_zone) { 'Wellington' }
  let(:currency) { 'NZD' }

  let(:time_zone_hk) { 'Hong Kong' }
  let(:distributor_hk) { Fabricate(:distributor, time_zone: time_zone_hk, currency: 'HKD') }
  let(:customer_hk) { Fabricate(:customer, distributor: distributor_hk) }

  context 'as admin' do
    sign_in_as_admin

    before { get :index }

    specify { Time.zone.name.should == time_zone }
  end

  context 'as distributor' do
    context 'default' do
      sign_in_as_distributor

      before { get :index }

      specify { Time.zone.name.should == time_zone }
    end

    context 'in Hong Kong' do
      before do
        @distributor = distributor_hk
        self.distributor_sign_in
        get :index
      end

      specify { Time.zone.name.should == time_zone_hk }
    end
  end

  context 'as customer' do
    context 'default' do
      sign_in_as_customer

      before { get :index }

      specify { Time.zone.name.should == time_zone }
    end

    context 'in Hong Kong' do
      before do
        @customer = customer_hk
        self.customer_sign_in
        get :index
      end

      specify { Time.zone.name.should == time_zone_hk }
    end
  end

  # NOTE: This is here solely to test the application controller
  controller do
    def index
      render nothing: true
    end
  end
end
