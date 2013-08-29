class Distributor; end # I don't want to touch the huge AR model let alone require it here.
require_relative "../../../app/models/distributor/setup"

describe Distributor::Setup do
  let(:distributor)       { double("distributor") }
  let(:distributor_setup) { Distributor::Setup.new(distributor) }

  before do
    distributor.stub(:delivery_services) { [] }
    distributor.stub(:boxes)             { [] }
    distributor.stub(:customers)         { [] }
  end

  describe "#finished?" do
    it "returns false if everything has been set up" do
      expect(distributor_setup.finished?).to be_false
    end

    it "returns true if everything has been set up" do
      distributor.stub(:delivery_services) { [ double("delivery_service") ] }
      distributor.stub(:boxes)             { [ double("boxes") ] }
      distributor.stub(:customers)         { [ double("customers") ] }
      expect(distributor_setup.finished?).to be_true
    end
  end

  describe "#progress" do
    it "returns a percentage of progress" do
      expect(distributor_setup.progress).to eql(0.0)

      distributor.stub(:delivery_services) { [ double("delivery_service") ] }
      expect(distributor_setup.progress).to eql(33.33333333333333)

      distributor.stub(:boxes) { [ double("boxes") ] }
      expect(distributor_setup.progress).to eql(66.66666666666666)

      distributor.stub(:customers) { [ double("customers") ] }
      expect(distributor_setup.progress).to eql(100.0)
    end
  end

  describe "#progress_left" do
    it "returns a percentage of progress" do
      expect(distributor_setup.progress_left).to eql(100.0)

      distributor.stub(:delivery_services) { [ double("delivery_service") ] }
      expect(distributor_setup.progress_left).to eql(66.66666666666667)

      distributor.stub(:boxes) { [ double("boxes") ] }
      expect(distributor_setup.progress_left).to eql(33.33333333333334)

      distributor.stub(:customers) { [ double("customers") ] }
      expect(distributor_setup.progress_left).to eql(0.0)
    end
  end
end
