require 'spec_helper'

describe MarketController do

  describe "GET 'buy'" do
    it "returns http success" do
      get 'buy'
      response.should be_success
    end
  end

  describe "GET 'specify'" do
    it "returns http success" do
      get 'specify'
      response.should be_success
    end
  end

  describe "GET 'customer_details'" do
    it "returns http success" do
      get 'customer_details'
      response.should be_success
    end
  end

  describe "GET 'payment'" do
    it "returns http success" do
      get 'payment'
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
