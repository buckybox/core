require "spec_helper"

RSpec.describe Import::Extra::Extra, type: :model do

  describe "#find" do

    let(:match)       { instance_double(Extra) }
    let(:matcher)     { instance_double(Import::Extra::Matcher, closest_match: match) }
    let(:matches)     { instance_double(Import::Extra::Matches) }
    let(:distributor) { instance_double(Distributor) }
    let(:extra)       { instance_double(Extra) }

    before do
      allow(Import::Extra::Matcher).to receive(:new).and_return(matcher)
      allow(Import::Extra::Matches).to receive(:by_fuzzy_match).and_return(matches)
    end

    context "when a box is not passed in" do

      it "returns the matched extra" do
        import_extra = Import::Extra.new(distributor: distributor, extra: extra)
        expect(import_extra.find).to eq(match)
      end

    end

    context "when a box is passed in" do

      let(:box) { instance_double(Box, present?: true) }

      it "finds the import box from the distributor" do
        expect(distributor).to receive(:find_box_from_import).with(box).and_return(box)
        import_extra = Import::Extra.new(distributor: distributor, extra: extra, box: box)
        import_extra.find
      end

      it "works" do
        allow(distributor).to receive(:find_box_from_import).and_return(box)
        import_extra = Import::Extra.new(distributor: distributor, extra: extra, box: box)
        expect(import_extra.find).to eq(match)
      end

    end

  end

end
