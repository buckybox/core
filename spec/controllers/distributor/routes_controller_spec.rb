require 'spec_helper'

describe Distributor::RoutesController do
  render_views

  as_distributor
  before { @customer = Fabricate(:customer, distributor: @distributor) }

  describe '#create' do
    context 'with valid params' do
      before(:each) do
        post :create, {
          route: {
            name: 'yoda', fee: '34', monday: '1', tuesday: '1', wednesday: '0', thursday: '0',
            friday: '0', saturday: '0', sunday: '0'
          }
        }
      end

      specify { flash[:notice].should eq('Route was successfully created.') }
      specify { assigns(:route).name.should eq('yoda') }
      specify { response.should redirect_to(distributor_settings_routes_url) }
    end

    context 'with invalid params' do
      before(:each) do
        post :create, { route: { name: 'yoda', fee: '34' } }
      end

      specify { assigns(:route).name.should eq('yoda') }
      specify { response.should render_template('routes/new') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before(:each) do
        @route = Fabricate(:route, distributor: @distributor, tuesday: false)
        put :update, { id: @route.id, route: { tuesday: '1' } }
      end

      specify { flash[:notice].should eq('Route was successfully updated.') }
      specify { assigns(:route).tuesday.should eq(true) }
      specify { response.should redirect_to(distributor_settings_routes_url) }
    end

    context 'with invalid params' do
      before(:each) do
        @route = Fabricate(:route, distributor: @distributor, tuesday: true)
        put :update, { id: @route.id, route: { monday: '0', tuesday: '0', wednesday: '0', thursday: '0', friday: '0', saturday: '0', sunday: '0' } }
      end

      specify { assigns(:route).tuesday.should eq(false) }
      specify { response.should render_template('routes/edit') }
    end
  end
end

