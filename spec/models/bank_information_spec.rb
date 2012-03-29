require 'spec_helper'

describe BankInformation do
  before do
    @bank_information = Fabricate.build(:bank_information)
  end

  specify { @bank_information.should be_valid }
end

