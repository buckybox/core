require 'spec_helper'

describe BankStatement do
  before :all do
    @statement = Fabricate.build(:bank_statement)
  end

  specify {@statement.should be_valid}

  context '#process_statement!' do
    before {@statement.process_statement!}
    specify{true}
  end

  context '#create_payment!' do
  end
end
