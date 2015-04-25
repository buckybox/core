require 'spec_helper'

describe Box do
  let(:box) { Fabricate.build(:box) }

  specify { expect(box).to be_valid }
end
