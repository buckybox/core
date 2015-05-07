class Distributor; end # I don't want to touch the huge AR model let alone require it here.
require_relative "../../../app/models/distributor/setup"

describe Distributor::Setup do
  let(:distributor)       { double("distributor") }
  let(:distributor_setup) { Distributor::Setup.new(distributor) }

  before do
    allow(distributor).to receive(:delivery_services) { [] }
    allow(distributor).to receive(:boxes)             { [] }
    allow(distributor).to receive(:customers)         { [] }
  end

  describe "#finished?" do
    it "returns false if everything has been set up" do
      expect(distributor_setup.finished?).to be false
    end

    it "returns true if everything has been set up" do
      allow(distributor).to receive(:delivery_services) { [double("delivery_service")] }
      allow(distributor).to receive(:boxes)             { [double("boxes")] }
      allow(distributor).to receive(:customers)         { [double("customers")] }
      expect(distributor_setup.finished?).to be true
    end
  end

  describe "#total_steps" do
    it "returns the total number of steps for setup" do
      expect(distributor_setup.total_steps).to eql(3)
    end
  end

  describe "#steps_done" do
    it "returns the steps completed so far" do
      expect(distributor_setup.steps_done).to eql(0)

      allow(distributor).to receive(:delivery_services) { [double("delivery_service")] }
      expect(distributor_setup.steps_done).to eql(1)

      allow(distributor).to receive(:boxes) { [double("boxes")] }
      expect(distributor_setup.steps_done).to eql(2)

      allow(distributor).to receive(:customers) { [double("customers")] }
      expect(distributor_setup.steps_done).to eql(3)
    end
  end

  describe "#progress" do
    it "returns a percentage of progress" do
      expect(distributor_setup.progress).to eql(0.0)

      allow(distributor).to receive(:delivery_services) { [double("delivery_service")] }
      expect(distributor_setup.progress).to eql(33.33333333333333)

      allow(distributor).to receive(:boxes) { [double("boxes")] }
      expect(distributor_setup.progress).to eql(66.66666666666666)

      allow(distributor).to receive(:customers) { [double("customers")] }
      expect(distributor_setup.progress).to eql(100.0)
    end
  end

  describe "#progress_left" do
    it "returns a percentage of progress" do
      expect(distributor_setup.progress_left).to eql(100.0)

      allow(distributor).to receive(:delivery_services) { [double("delivery_service")] }
      expect(distributor_setup.progress_left).to eql(66.66666666666667)

      allow(distributor).to receive(:boxes) { [double("boxes")] }
      expect(distributor_setup.progress_left).to eql(33.33333333333334)

      allow(distributor).to receive(:customers) { [double("customers")] }
      expect(distributor_setup.progress_left).to eql(0.0)
    end
  end

  describe "#finished_settings?" do
    it "returns false if no settings have been completed" do
      expect(distributor_setup.finished_settings?).to be false
    end

    it "returns false if there are no delivery services" do
      allow(distributor).to receive(:boxes) { [double("boxes")] }
      expect(distributor_setup.finished_settings?).to be false
    end

    it "returns false if there are no boxes" do
      allow(distributor).to receive(:delivery_services) { [double("delivery_service")] }
      expect(distributor_setup.finished_settings?).to be false
    end

    it "returns true if the settings setup is done" do
      allow(distributor).to receive(:delivery_services) { [double("delivery_service")] }
      allow(distributor).to receive(:boxes)             { [double("boxes")] }
      expect(distributor_setup.finished_settings?).to be true
    end
  end
end
