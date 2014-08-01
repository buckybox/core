require 'spec_helper'

describe Transaction do
  let(:transaction) { Fabricate(:transaction) }

  specify { expect(transaction).to be_valid }
end
