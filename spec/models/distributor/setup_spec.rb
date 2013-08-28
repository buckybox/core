class Distributor; end # I don't want to touch the huge AR model let alone require it here.
require_relative "../../../app/models/distributor/setup"

describe Distributor::Setup do
  let(:distributor)       { double("distributor") }
  let(:distributor_setup) { Distributor::Setup.new(distributor) }

  describe "#finished?" do
    it "returns false if everything has been set up" do
      distributor.stub(:routes) { [] }
      expect(distributor_setup.finished?).to be_false
    end

    it "returns true if everything has been set up" do
      distributor.stub(:routes) { [ double("route") ] }
      expect(distributor_setup.finished?).to be_true
    end
  end

  describe "#progress" do
    it "returns 0 if nothing is done" do
      distributor.stub(:routes) { [] }
      expect(distributor_setup.progress).to eq(0)
    end

    it "returns 100 if nothing is done" do
      distributor.stub(:routes) { [ double("route") ] }
      expect(distributor_setup.progress).to eq(100)
    end
  end

  describe "#progress_left" do
    it "returns 0 if nothing is done" do
      distributor.stub(:routes) { [] }
      expect(distributor_setup.progress_left).to eq(100)
    end

    it "returns 100 if nothing is done" do
      distributor.stub(:routes) { [ double("route") ] }
      expect(distributor_setup.progress_left).to eq(0)
    end
  end
end
