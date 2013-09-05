require 'spec_helper'

describe Admin::DistributorsController do
  sign_in_as_admin

  specify { subject.current_admin.should_not be_nil }

  describe 'GET index' do
    it 'assigns all distributors as @distributors' do
      # NOTE: prevent random failure when existing distributors would not be
      # wiped out by DatabaseCleaner
      Distributor.delete_all

      distributor = Fabricate(:distributor)
      get :index, {}
      assigns(:distributors).should eq([distributor])
    end
  end

  describe 'GET show' do
    it 'assigns the requested admin_distributor as @admin_distributor' do
      distributor = Fabricate(:distributor)
      get :show, { id: distributor.to_param }
      assigns(:distributor).should eq(distributor)
    end
  end

  describe 'GET new' do
    it 'assigns a new admin_distributor as @admin_distributor' do
      get :new, {}
      assigns(:distributor).should be_a_new(Distributor)
    end
  end

  describe 'GET edit' do
    it 'assigns the requested admin_distributor as @admin_distributor' do
      distributor = Fabricate(:distributor)
      get :edit, { id: distributor.to_param }
      assigns(:distributor).should eq(distributor)
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new distributor' do
        expect {
          post :create, { distributor: Fabricate.attributes_for(:distributor) }
        }.to change(Distributor, :count).by(1)
      end

      it 'adds default line items to distributor' do
        expect {
          post :create, { distributor: Fabricate.attributes_for(:distributor) }
        }.to change(LineItem, :count).by(LineItem::DEFAULT_LIST.split(",").size)
      end

      it 'assigns a newly created admin_distributor as @admin_distributor' do
        post :create, { distributor: Fabricate.attributes_for(:distributor) }
        assigns(:distributor).should be_a(Distributor)
        assigns(:distributor).should be_persisted
      end

      it 'redirects to the created admin_distributor' do
        post :create, { distributor: Fabricate.attributes_for(:distributor) }
        response.should redirect_to(admin_distributor_path(Distributor.last))
      end
    end

    describe 'with invalid params' do
      it 'assigns a newly created but unsaved admin_distributor as @admin_distributor' do
        # Trigger the behavior that occurs when invalid params are submitted
        post :create, { distributor: {} }
        assigns(:distributor).should be_a(Distributor)
        assigns(:distributor).should_not be_persisted
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      it 'assigns the requested admin_distributor as @admin_distributor' do
        distributor = Fabricate(:distributor)
        put :update, { id: distributor.to_param, distributor: Fabricate.attributes_for(:distributor) }
        assigns(:distributor).should eq(distributor)
      end

      it 'redirects to the admin_distributor' do
        distributor = Fabricate(:distributor)
        put :update, { id: distributor.to_param, distributor: Fabricate.attributes_for(:distributor) }
        response.should redirect_to(admin_distributor_path(distributor))
      end
    end

    describe 'with invalid params' do
      it 'assigns the admin_distributor as @admin_distributor' do
        distributor = Fabricate(:distributor)
        put :update, { id: distributor.to_param, distributor: {} }
        assigns(:distributor).should eq(distributor)
      end
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the requested admin_distributor' do
      distributor = Fabricate(:distributor)
      expect {
        delete :destroy, { id: distributor.to_param }
      }.to change(Distributor, :count).by(-1)
    end

    it 'redirects to the distributors list' do
      distributor = Fabricate(:distributor)
      delete :destroy, { id: distributor.to_param }
      response.should redirect_to(admin_distributors_url)
    end
  end

  describe 'impersonate' do
    it 'should sign in as a distributor' do
      get :impersonate, id: Fabricate(:distributor).id
      response.should redirect_to(distributor_root_url)
    end
  end

  describe 'unimpersonate' do
    sign_in_as_distributor

    specify { subject.current_distributor.should_not be_nil }

    it 'should sign out as distributor' do
      get :unimpersonate
      @controller.distributor_signed_in?.should be_false
    end
  end

  describe 'country_setting' do
    sign_in_as_distributor
    before do
      c = double(Country, default_time_zone: "Pacific/Auckland",
                default_currency: "nzd",
                default_consumer_fee_cents: 20)
      Country.should_receive(:find).with("32").and_return(c)
    end

    it 'should return country settings for distributor form' do
      get :country_setting, id: 32
      country = JSON.parse(response.body)
      country['time_zone'].should eq("Auckland")
      country['currency'].should eq("NZD")
      country['fee'].should eq(0.2)
    end
  end
end
