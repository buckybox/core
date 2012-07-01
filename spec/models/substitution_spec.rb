require 'spec_helper'

describe Substitution do
  let(:substitution) { Fabricate.build(:substitution) }

  specify { substitution.should be_valid }

  describe '.change_line_items!' do
    before do
      @old_line_item  = Fabricate(:line_item)
      @substitution_1 = Fabricate(:substitution, line_item: @old_line_item)
      @substitution_2 = Fabricate(:substitution, line_item: @old_line_item)
      @new_line_item  = Fabricate(:line_item)
      Substitution.change_line_items!(@old_line_item, @new_line_item)
    end

    specify { @old_line_item.substitutions(true).to_a.should == [] }
    specify { @new_line_item.substitutions(true).to_a.should == [@substitution_1, @substitution_2] }
  end
end
