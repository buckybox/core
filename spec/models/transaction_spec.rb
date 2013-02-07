require 'spec_helper'

describe Transaction do
  let(:transaction) { Fabricate(:transaction) }

  specify { transaction.should be_valid }
end
