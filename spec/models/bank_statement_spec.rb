require 'spec_helper'
require 'csv'

describe BankStatement do
  before :each do
    @statement = Fabricate(:bank_statement)
    @customer = Fabricate(:customer)
  end

  specify {@statement.should be_valid}

  context '#process_statement!' do
    before do
      @customers_ids = {}
      i = 0
      CSV.foreach(@statement.statement_file.path, :headers => true) do |row|
        if row['Amount'].to_i > 0
          @customers_ids["#{i}"] = @customer.id.to_s
          i+=1
        end
      end
    end

    specify do
      @statement.should_receive('create_payment!').exactly(@customers_ids.length).times
      @statement.process_statement! @customers_ids
    end
    
    specify do
      @statement.save!
      @statement.process_statement! @customers_ids
      Payment.last.statement_id.should == @statement.id
    end
  end
end
