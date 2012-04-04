require 'spec_helper'

describe Box do
  before do
    @box = Fabricate.build(:box)
  end

  specify { @box.should be_valid }
end
