require 'spec_helper'

describe Admin::DistributorsController do
  as_admin

  describe "GET index" do
    it "assigns all distributors as @distributors" do
      distributor = Distributor.create! Fabricate.attributes_for(:distributor)
      get :index, {}
      assigns(:distributors).should eq([distributor])
    end
  end

  describe "GET show" do
    it "assigns the requested admin_distributor as @admin_distributor" do
      distributor = Distributor.create! Fabricate.attributes_for(:distributor)
      get :show, {:id => distributor.to_param}
      assigns(:distributor).should eq(distributor)
    end
  end

  describe "GET new" do
    it "assigns a new admin_distributor as @admin_distributor" do
      get :new, {}
      assigns(:distributor).should be_a_new(Distributor)
    end
  end

  describe "GET edit" do
    it "assigns the requested admin_distributor as @admin_distributor" do
      distributor = Distributor.create! Fabricate.attributes_for(:distributor)
      get :edit, {:id => distributor.to_param}
      assigns(:distributor).should eq(distributor)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Distributor" do
        expect {
          post :create, {:distributor => Fabricate.attributes_for(:distributor)}
        }.to change(Distributor, :count).by(1)
      end

      it "assigns a newly created admin_distributor as @admin_distributor" do
        post :create, {:distributor => Fabricate.attributes_for(:distributor)}
        assigns(:distributor).should be_a(Distributor)
        assigns(:distributor).should be_persisted
      end

      it "redirects to the created admin_distributor" do
        post :create, {:distributor => Fabricate.attributes_for(:distributor)}
        response.should redirect_to(admin_distributor_path(Distributor.last))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved admin_distributor as @admin_distributor" do
        # Trigger the behavior that occurs when invalid params are submitted
        Distributor.any_instance.stub(:save).and_return(false)
        post :create, {:distributor => {}}
        assigns(:distributor).should be_a_new(Distributor)
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested admin_distributor" do
        distributor = Distributor.create! Fabricate.attributes_for(:distributor)
        # Assuming there are no other distributors in the database, this
        # specifies that the Admin::Distributor created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Distributor.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => distributor.to_param, :distributor => {'these' => 'params'}}
      end

      it "assigns the requested admin_distributor as @admin_distributor" do
        distributor = Distributor.create! Fabricate.attributes_for(:distributor)
        put :update, {:id => distributor.to_param, :distributor => Fabricate.attributes_for(:distributor)}
        assigns(:distributor).should eq(distributor)
      end

      it "redirects to the admin_distributor" do
        distributor = Distributor.create! Fabricate.attributes_for(:distributor)
        put :update, {:id => distributor.to_param, :distributor => Fabricate.attributes_for(:distributor)}
        response.should redirect_to(admin_distributor_path(distributor))
      end
    end

    describe "with invalid params" do
      it "assigns the admin_distributor as @admin_distributor" do
        distributor = Distributor.create! Fabricate.attributes_for(:distributor)
        # Trigger the behavior that occurs when invalid params are submitted
        Distributor.any_instance.stub(:save).and_return(false)
        put :update, {:id => distributor.to_param, :distributor => {}}
        assigns(:distributor).should eq(distributor)
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested admin_distributor" do
      distributor = Distributor.create! Fabricate.attributes_for(:distributor)
      expect {
        delete :destroy, {:id => distributor.to_param}
      }.to change(Distributor, :count).by(-1)
    end

    it "redirects to the distributors list" do
      distributor = Distributor.create! Fabricate.attributes_for(:distributor)
      delete :destroy, {:id => distributor.to_param}
      response.should redirect_to(admin_distributors_url)
    end
  end

  describe "impersonate" do
    it "should sign in as a distributor" do
      get :impersonate, :id => Fabricate(:distributor).id
      @controller.distributor_signed_in?.should be_true
    end
  end

  describe "unimpersonate" do
    as_distributor

    specify { @controller.distributor_signed_in?.should be_true }

    it "should sign out as distributor" do
      get :unimpersonate
      @controller.distributor_signed_in?.should be_false
    end
  end
end
