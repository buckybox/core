require 'spec_helper'

describe Exclusion do
  let(:exclusion) { Fabricate.build(:exclusion) }

  specify { exclusion.should be_valid }
end
