require "spec_helper"

RSpec.describe Import::Extra::Matcher, type: :model do

  describe "#closest_match" do

    let(:extra)    { instance_double(Extra) }
    let(:extra_m0) { instance_double(Extra, name: "Ale", unit: 2) }
    let(:match_0)  { [ 0.30, extra_m0 ] }
    let(:extra_m1) { instance_double(Extra, name: "Apple", unit: 3) }
    let(:match_1)  { [ 0.99, extra_m1 ] }

    context "when at least the first two matches have the same fuzzy matches" do

      it "returns the first extra match" do
        extra_m2 = instance_double(Extra, name: "Apple", unit: 3)
        match_2  = [ 0.99, extra_m2 ]
        matches  = [ match_1, match_2, match_0 ]
        matcher  = Import::Extra::Matcher.new(match: extra, from: matches)
        expect(matcher.closest_match).to eq(extra_m1)
      end

    end

    context "when at least the first two matches have the differet fuzzy matches" do

      it "returns the second extra match" do
        extra_m2 = instance_double(Extra, name: "Appl3", unit: 3)
        match_2  = [ 0.95, extra_m2 ]
        matches  = [ match_2, match_1, match_0 ]
        matcher  = Import::Extra::Matcher.new(match: extra, from: matches)
        expect(matcher.closest_match).to eq(extra_m2)
      end

    end

    context "when there is at least one match" do

      it "returns the first extra" do
        matches = [ match_1 ]
        matcher = Import::Extra::Matcher.new(match: extra, from: matches)
        expect(matcher.closest_match).to eq(extra_m1)
      end

    end

  end

end
