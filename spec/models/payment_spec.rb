require 'spec_helper'

describe Payment do
  before :all do
    @payment = Fabricate(:payment)
  end

  specify { @payment.should be_valid }
end

