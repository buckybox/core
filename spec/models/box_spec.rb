require 'spec_helper'

describe Box do
  before do
    @box = Box.make
  end

  specify { @box.should be_valid }
end
