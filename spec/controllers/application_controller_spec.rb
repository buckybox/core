require 'spec_helper'

describe ApplicationController do
  let(:default_time_zone) { 'Wellington' }
  let(:default_currency) { 'NZD' }

  let(:time_zone) { 'Hong Kong' }
  let(:currency) { 'HKD' }
  let(:distributor_hk) { Fabricate(:distributor, time_zone: time_zone, currency: currency) }
  let(:customer_hk) { Fabricate(:customer, distributor: distributor_hk) }

  context 'as admin' do
    sign_in_as_admin

    before { get :index }

    specify { Time.zone.name.should == default_time_zone }
  end

  context 'as distributor' do
    context 'default' do
      sign_in_as_distributor

      before { get :index }

      specify { Time.zone.name.should == default_time_zone }
    end

    context 'in hong kong' do
      before do
        @distributor = distributor_hk
        self.distributor_sign_in
        get :index
      end

      specify { Time.zone.name.should == time_zone }
    end
  end

  context 'as customer' do
    context 'default' do
      sign_in_as_customer

      before { get :index }

      specify { Time.zone.name.should == default_time_zone }
    end

    context 'in hong kong' do
      before do
        @customer = customer_hk
        self.customer_sign_in
        get :index
      end

      specify { Time.zone.name.should == time_zone }
    end
  end

  #----- This is here solely to test the application controller
  controller do
    def index
      render nothing: true
    end
  end
end
