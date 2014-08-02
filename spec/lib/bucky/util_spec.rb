require 'spec_helper'

describe Bucky::Util do
  describe "#fuzzy_match" do
     specify{ expect(Bucky::Util.fuzzy_match("Orange Juice", "orange juice")).to eq(1)}
     specify{ expect(Bucky::Util.fuzzy_match("Orange Juice", "oronge juice")).to be < 0.96}
     specify{ expect(Bucky::Util.fuzzy_match("Orange Juice", "oronge juice")).to be > 0.95}
     specify{ expect(Bucky::Util.fuzzy_match("abcdef", "hijklmn")).to eq(0)}
     specify{ expect(Bucky::Util.fuzzy_match("abcd", "dcba")).to eq(0.5)}
  end
end
