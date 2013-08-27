class Distributor; end # I don't want to touch the huge AR model let alone require it here.
require_relative "../../../app/models/distributor/setup"

describe Distributor::Setup do
  let(:distributor)       { double("distributor") }
  let(:distributor_setup) { Distributor::Setup.new(distributor) }

  describe "#done?" do
    it "returns false if everything has been set up" do
      distributor.stub(:routes) { [] }
      expect(distributor_setup.done?).to be_false
    end

    it "returns true if everything has been set up" do
      distributor.stub(:routes) { [ double("route") ] }
      expect(distributor_setup.done?).to be_true
    end
  end
end
