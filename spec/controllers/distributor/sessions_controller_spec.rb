require 'spec_helper'

describe Distributor::SessionsController do
  before do
    request.env["devise.mapping"] = Devise.mappings[:distributor]
  end

  describe "#new" do
    it "is successful" do
      get :new

      response.should be_successful
    end
  end
end

