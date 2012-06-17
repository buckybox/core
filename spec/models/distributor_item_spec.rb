require 'spec_helper'

describe DistributorItem do
  let(:distributor_item) { Fabricate.build(:distributor_item) }

  specify { distributor_item.should be_valid }
end
