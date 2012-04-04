require 'spec_helper'

describe Box do
  let (:box) { Fabricate.build(:box) }

  specify { box.should be_valid }
end
