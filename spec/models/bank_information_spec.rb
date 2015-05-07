require 'spec_helper'

describe BankInformation do
  before do
    @bank_information = Fabricate.build(:bank_information)
  end

  specify { expect(@bank_information).to be_valid }
end
