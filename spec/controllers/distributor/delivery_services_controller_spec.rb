require 'spec_helper'

describe Distributor::DeliveryServicesController do
  render_views

  sign_in_as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#create' do
    context 'with valid params' do
      before do
        post :create, {
          delivery_service: {
            name: 'yoda', fee: '34', schedule_rule_attributes: {mon: '1', tue: '1', wed: '0', thu: '0',
            fri: '0', sat: '0', sun: '0'}, area_of_service: 'aos', estimated_delivery_time: 'edt'
          }
        }
      end

      specify { flash[:notice].should eq('Delivery service was successfully created.') }
      specify { assigns(:delivery_service).name.should eq('yoda') }
      specify { response.should redirect_to(distributor_settings_delivery_services_url) }
      specify { assigns(:delivery_service).schedule_rule.recur.should eq(:weekly)}
    end

    context 'with invalid params' do
      before do
        post :create, { delivery_service: { name: 'yoda', fee: '34' } }
      end

      specify { assigns(:delivery_service).name.should eq('yoda') }
      specify { response.should render_template('delivery_services/new') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before do
        @delivery_service = Fabricate(:delivery_service, distributor: @distributor, schedule_rule_attributes: {tue: true})
        put :update, { id: @delivery_service.id, delivery_service: { schedule_rule_attributes: {tue: '1' } } }
      end

      specify { flash[:notice].should eq('Delivery service was successfully updated.') }
      specify { assigns(:delivery_service).schedule_rule.tue.should be_true }
      specify { response.should redirect_to(distributor_settings_delivery_services_url) }
    end

    context 'with invalid params' do
      before do
        @delivery_service = Fabricate(:delivery_service, distributor: @distributor, schedule_rule_attributes: {tue: true})
        put :update, { id: @delivery_service.id, delivery_service: { schedule_rule_attributes: {mon: '0', tue: '0', wed: '0', thu: '0', fri: '0', sat: '0', sun: '0' } } }
      end

      specify { assigns(:delivery_service).schedule_rule.tue.should eq(false) }
      specify { response.should render_template('delivery_services/edit') }
    end
  end
end

