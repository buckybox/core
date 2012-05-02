require 'spec_helper'

describe Bucky::Util do
  describe "#fuzzy_match" do
     specify{ Bucky::Util.fuzzy_match("Orange Juice", "orange juice").should eq(1)}
     specify{ Bucky::Util.fuzzy_match("Orange Juice", "oronge juice").should be < 0.96}
     specify{ Bucky::Util.fuzzy_match("Orange Juice", "oronge juice").should be > 0.95}
     specify{ Bucky::Util.fuzzy_match("abcdef", "hijklmn").should eq(0)}
     specify{ Bucky::Util.fuzzy_match("abcd", "dcba").should eq(0.5)}
  end
end
