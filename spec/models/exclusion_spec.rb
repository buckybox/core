require 'spec_helper'

describe Exclusion do
  let(:exclusion) { Fabricate.build(:exclusion) }

  specify { exclusion.should be_valid }

  describe '.change_line_items!' do
    before do
      @old_line_item = Fabricate(:line_item)
      @exclusion_1   = Fabricate(:exclusion, line_item: @old_line_item)
      @exclusion_2   = Fabricate(:exclusion, line_item: @old_line_item)
      @new_line_item = Fabricate(:line_item)
      Exclusion.change_line_items!(@old_line_item, @new_line_item)
    end

    specify { @old_line_item.exclusions(true).to_a.should == [] }
    specify { @new_line_item.exclusions(true).to_a.should == [@exclusion_1, @exclusion_2] }
  end
end
