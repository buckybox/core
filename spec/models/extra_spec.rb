require 'spec_helper'

describe Extra do
  let(:extra) { Fabricate.build(:extra) }

  specify { extra.should be_valid }
end
