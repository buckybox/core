require 'spec_helper'

describe Account do
  before :all do
    @account = Fabricate(:account)
  end

  specify { @account.should be_valid }
end

