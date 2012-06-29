require 'spec_helper'

describe Substitution do
  let(:substitution) { Fabricate.build(:substitution) }

  specify { substitution.should be_valid }
end
