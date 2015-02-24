require "spec_helper"

describe Distributor::Export::Utils do
  let(:utils) { Distributor::Export::Utils }

  describe ".determine_type" do
    it "determines the delivery key" do
      hash = { deliveries: [] }
      expect(utils.determine_type(hash)).to eq(:deliveries)
    end

    it "determines the package key" do
      hash = { packages: [] }
      expect(utils.determine_type(hash)).to eq(:packages)
    end

    it "determines the order key" do
      hash = { orders: [] }
      expect(utils.determine_type(hash)).to eq(:orders)
    end

    it "determines if no known key exists" do
      hash = { unknown_type: [] }
      expect(utils.determine_type(hash)).to eq(nil)
    end
  end

  describe "CSV export builder" do
    let(:type) { :deliveries }
    let(:args) do
      { distributor: "Vegies", deliveries: [1], date: "2015-02-22", screen: true }
    end
    let(:expected) do
      { distributor: "Vegies", ids: [1], date: Date.parse("2015-02-22"), screen: true }
    end

    describe ".build_csv_exporter_constant" do
      it "creates an export constant" do
        expect(utils.build_csv_exporter_constant(type)).to eq(SalesCsv::DeliveryExporter)
      end
    end

    describe ".build_csv_args" do
      it "creates the csv arguments" do
        expect(utils.build_csv_args(type, args)).to eq(expected)
      end
    end

    describe ".build_csv" do
      it "creates a CSV exporter instance" do
        expect(SalesCsv::DeliveryExporter).to receive(:new).with(expected)
        utils.build_csv(type, args)
      end
    end

    describe ".get_export" do
      let(:result)      { double("result") }
      let(:distributor) { instance_double("Distributor") }

      before do
        allow(SalesCsv::DeliveryExporter).to receive(:new).and_return(result)
      end

      it "creates a CSV exporter instance if the right type is provided" do
        expect(utils.get_export(distributor, args)).to eq(result)
      end

      it "does not create a CSV exporter instance if the type is wrong" do
        args.delete(:deliveries)
        expect(utils.get_export(distributor, args)).to eq(nil)
      end
    end
  end
end
