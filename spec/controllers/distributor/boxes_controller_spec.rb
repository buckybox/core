require 'spec_helper'

describe Distributor::BoxesController do
  render_views

  before(:each) do
    @distributor = Fabricate(:distributor, :completed_wizard => true)
    @customer = Fabricate(:customer, :distributor => @distributor)
    sign_in @distributor
  end

  describe '#create' do
    context 'with valid params' do
      before(:each) do
        post :create, {box: {name: "yodas box", price: "246", likes: "1", dislikes: "1", available_single: "1", available_weekly: "0", available_fourtnightly: "1", description: "tasty selection of herbs from Yoda's garden."}, distributor_id: @distributor.id}
      end
      specify { flash[:notice].should eq("Box was successfully created.") }
      specify { assigns(:box).name.should eq("yodas box") }
      specify { response.should redirect_to(boxes_distributor_settings_path(@distributor)) }
    end
    context 'with invalid params' do
      before(:each) do
        post :create, {box: {name: "yoda"}, distributor_id: @distributor.id}
      end
      specify { assigns(:box).name.should eq('yoda') }
      specify { response.should render_template('boxes/new') }
    end
  end

  describe '#update' do
    context 'with valid params' do
      before(:each) do
        @box = Fabricate(:box, distributor: @distributor, price: 234)
        put :update, {id: @box.id, box: {price: 123}, distributor_id: @distributor.id}
      end
      specify { flash[:notice].should eq("Box was successfully updated.") }
      specify { assigns(:box).price.should eq(123) }
      specify { response.should redirect_to(boxes_distributor_settings_path(@distributor)) }
    end
    context 'with invalid params' do
      before(:each) do
        @box = Fabricate(:box, distributor: @distributor, price: 234)
        put :update, {id: @box.id, box: {name: ''}, distributor_id: @distributor.id}
      end
      specify { assigns(:box).price.should eq(234) }
      specify { response.should render_template('boxes/edit') }
    end
  end
end

