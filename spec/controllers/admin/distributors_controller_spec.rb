require 'spec_helper'

describe Admin::DistributorsController do
  sign_in_as_admin

  specify { expect(subject.current_admin).not_to be_nil }

  describe 'GET index' do
    it 'assigns all distributors as @distributors' do
      # NOTE: prevent random failure when existing distributors would not be
      # wiped out by DatabaseCleaner
      Distributor.delete_all

      distributor = Fabricate(:distributor)
      get :index, {}
      expect(assigns(:distributors)).to eq([distributor])
    end
  end

  describe 'GET show' do
    it 'assigns the requested admin_distributor as @admin_distributor' do
      distributor = Fabricate(:distributor)
      get :show, { id: distributor.to_param }
      expect(assigns(:distributor)).to eq(distributor)
    end
  end

  describe 'GET new' do
    it 'assigns a new admin_distributor as @admin_distributor' do
      get :new, {}
      expect(assigns(:distributor)).to be_a_new(Distributor)
    end
  end

  describe 'GET edit' do
    it 'assigns the requested admin_distributor as @admin_distributor' do
      distributor = Fabricate(:distributor)
      get :edit, { id: distributor.to_param }
      expect(assigns(:distributor)).to eq(distributor)
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new distributor' do
        expect do
          post :create, { distributor: Fabricate.attributes_for(:distributor) }
        end.to change(Distributor, :count).by(1)
      end

      it 'adds default line items to distributor' do
        expect do
          post :create, { distributor: Fabricate.attributes_for(:distributor) }
        end.to change(LineItem, :count).by(LineItem::DEFAULT_LIST.split(",").size)
      end

      it 'assigns a newly created admin_distributor as @admin_distributor' do
        post :create, { distributor: Fabricate.attributes_for(:distributor) }
        expect(assigns(:distributor)).to be_a(Distributor)
        expect(assigns(:distributor)).to be_persisted
      end

      it 'redirects to the created admin_distributor' do
        post :create, { distributor: Fabricate.attributes_for(:distributor) }
        expect(response).to redirect_to(admin_distributor_path(Distributor.last))
      end
    end

    describe 'with invalid params' do
      it 'assigns a newly created but unsaved admin_distributor as @admin_distributor' do
        # Trigger the behavior that occurs when invalid params are submitted
        post :create, { distributor: {} }
        expect(assigns(:distributor)).to be_a(Distributor)
        expect(assigns(:distributor)).not_to be_persisted
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      it 'assigns the requested admin_distributor as @admin_distributor' do
        distributor = Fabricate(:distributor)
        put :update, { id: distributor.to_param, distributor: Fabricate.attributes_for(:distributor) }
        expect(assigns(:distributor)).to eq(distributor)
      end

      it 'redirects to the admin_distributor' do
        distributor = Fabricate(:distributor)
        put :update, { id: distributor.to_param, distributor: Fabricate.attributes_for(:distributor) }
        expect(response).to redirect_to(admin_distributor_path(distributor))
      end
    end

    describe 'with invalid params' do
      it 'assigns the admin_distributor as @admin_distributor' do
        distributor = Fabricate(:distributor)
        put :update, { id: distributor.to_param, distributor: {} }
        expect(assigns(:distributor)).to eq(distributor)
      end
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the requested admin_distributor' do
      distributor = Fabricate(:distributor)
      expect do
        delete :destroy, { id: distributor.to_param }
      end.to change(Distributor, :count).by(-1)
    end

    it 'redirects to the distributors list' do
      distributor = Fabricate(:distributor)
      delete :destroy, { id: distributor.to_param }
      expect(response).to redirect_to(admin_distributors_url)
    end
  end

  describe 'impersonate' do
    it 'should sign in as a distributor' do
      get :impersonate, id: Fabricate(:distributor).id
      expect(response).to redirect_to(distributor_root_url)
    end
  end

  describe 'unimpersonate' do
    sign_in_as_distributor

    specify { expect(subject.current_distributor).not_to be_nil }

    it 'should sign out as distributor' do
      get :unimpersonate
      expect(@controller.distributor_signed_in?).to be false
    end
  end

  describe 'country_setting' do
    sign_in_as_distributor
    before do
      c = double(Country, time_zone: "Pacific/Auckland",
                currency: "NZD",
                default_consumer_fee_cents: 20)
      expect(Country).to receive(:find).with("32").and_return(c)
    end

    it 'should return country settings for distributor form' do
      get :country_setting, id: 32
      country = JSON.parse(response.body)
      expect(country['time_zone']).to eq("Auckland")
      expect(country['currency']).to eq("NZD")
      expect(country['fee']).to eq(0.2)
    end
  end
end
