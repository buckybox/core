require 'spec_helper'

describe Extra do
  before :all do
    @extra = Fabricate.build(:extra)
  end

  specify { @extra.should be_valid }
end
