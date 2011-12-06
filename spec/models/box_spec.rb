require 'spec_helper'

describe Box do
  before :all do
    @box = Fabricate(:box)
  end

  specify { @box.should be_valid }
end
