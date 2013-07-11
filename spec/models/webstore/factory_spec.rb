require_relative '../../../app/models/webstore/factory'

describe Webstore::Factory do

  describe "#initialize" do
    let(:cart) { double("Webstore::Cart") }

    it "accepts a cart" do
      Webstore::Factory.new cart
    end
  end

end

