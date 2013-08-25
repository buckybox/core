require 'spec_helper'

describe Distributor::RoutesController do
  render_views

  sign_in_as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#create' do
    context 'with valid params' do
      before do
        post :create, {
          route: {
            name: 'yoda', fee: '34', schedule_rule_attributes: {mon: '1', tue: '1', wed: '0', thu: '0',
            fri: '0', sat: '0', sun: '0'}, area_of_service: 'aos', estimated_delivery_time: 'edt'
          }
        }
      end

      specify { flash[:notice].should eq('Route was successfully created.') }
      specify { assigns(:route).name.should eq('yoda') }
      specify { response.should redirect_to(distributor_settings_routes_url) }
      specify { assigns(:route).schedule_rule.recur.should eq(:weekly)}
    end

    context 'with invalid params' do
      before do
        post :create, { route: { name: 'yoda', fee: '34' } }
      end

      specify { assigns(:route).name.should eq('yoda') }
      specify { response.should render_template('routes/new') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before do
        @route = Fabricate(:route, distributor: @distributor, schedule_rule_attributes: {tue: true})
        put :update, { id: @route.id, route: { schedule_rule_attributes: {tue: '1' } } }
      end

      specify { flash[:notice].should eq('Route was successfully updated.') }
      specify { assigns(:route).schedule_rule.tue.should be_true }
      specify { response.should redirect_to(distributor_settings_routes_url) }
    end

    context 'with invalid params' do
      before do
        @route = Fabricate(:route, distributor: @distributor, schedule_rule_attributes: {tue: true})
        put :update, { id: @route.id, route: { schedule_rule_attributes: {mon: '0', tue: '0', wed: '0', thu: '0', fri: '0', sat: '0', sun: '0' } } }
      end

      specify { assigns(:route).schedule_rule.tue.should eq(false) }
      specify { response.should render_template('routes/edit') }
    end
  end
end

