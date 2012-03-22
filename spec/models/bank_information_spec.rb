require 'spec_helper'

describe BankInformation do
  before do
    @bank_information = BankInformation.make
  end

  specify { @bank_information.should be_valid }
end

