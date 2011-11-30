require 'spec_helper'

describe Distributor::WizardController do

  describe "GET 'business'" do
    it "returns http success" do
      get 'business'
      response.should be_success
    end
  end

  describe "GET 'boxes'" do
    it "returns http success" do
      get 'boxes'
      response.should be_success
    end
  end

  describe "GET 'routes'" do
    it "returns http success" do
      get 'routes'
      response.should be_success
    end
  end

  describe "GET 'payment'" do
    it "returns http success" do
      get 'payment'
      response.should be_success
    end
  end

  describe "GET 'billing'" do
    it "returns http success" do
      get 'billing'
      response.should be_success
    end
  end

  describe "GET 'success'" do
    it "returns http success" do
      get 'success'
      response.should be_success
    end
  end

end
