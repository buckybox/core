require "spec_helper"

RSpec.describe Import::Extra::Matches, type: :model do

  describe ".by_fuzzy_match" do

    let(:matches) { instance_double(Import::Extra::Matches) }
    let(:args)    { { distributor: "distributor", extra: "extra", box: "box" } }

    it "creates a new instance" do
      expect(Import::Extra::Matches).to receive(:new).with(args).and_return(matches)
      allow(matches).to receive(:by_fuzzy_match)
      Import::Extra::Matches.by_fuzzy_match(args)
    end

    it "calls the fuzzy match method on the instance" do
      allow(Import::Extra::Matches).to receive(:new).and_return(matches)
      expect(matches).to receive(:by_fuzzy_match)
      Import::Extra::Matches.by_fuzzy_match(args)
    end

  end

  describe "#by_fuzzy_match" do

    let(:extra_1) { instance_double(Extra, match_import_extra?: false, fuzzy_match: 0.30) }
    let(:extra_2) { instance_double(Extra, match_import_extra?: true,  fuzzy_match: 0.91) }
    let(:extra_3) { instance_double(Extra, match_import_extra?: true,  fuzzy_match: 0.99) }
    let(:extras)  { double("extras", alphabetically: [ extra_1, extra_2, extra_3 ]) }
    let(:extra)   { instance_double(Extra) }

    context "when there is no box" do

      it "returns the two maching extras from the distributor" do
        distributor = instance_double(Distributor, extras: extras)
        box         = instance_double(Box, blank?: true)
        matches = Import::Extra::Matches.new(
          distributor: distributor,
          box: box,
          extra: extra
        )
        expect(matches.by_fuzzy_match).to eq([ [ 0.99, extra_3 ], [ 0.91, extra_2 ] ])
      end

    end

    context "when there is a box and the box allows extras" do

      it "returns the two maching extras from the box" do
        distributor = instance_double(Distributor)
        box         = instance_double(Box, blank?: false, extras_allowed?: true, extras: extras)
        matches = Import::Extra::Matches.new(
          distributor: distributor,
          box: box,
          extra: extra
        )
        expect(matches.by_fuzzy_match).to eq([ [ 0.99, extra_3 ], [ 0.91, extra_2 ] ])
      end

    end

    context "when there is a box and the box does not allow extras" do

      it "returns an empty array" do
        distributor = instance_double(Distributor)
        box         = instance_double(Box, blank?: false, extras_allowed?: false)
        matches = Import::Extra::Matches.new(
          distributor: distributor,
          box: box,
          extra: extra
        )
        expect(matches.by_fuzzy_match).to eq([])
      end

    end

  end

end
