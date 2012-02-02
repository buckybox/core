require 'spec_helper'
require 'csv'

describe BankStatement do
  before :each do
    @distributor = Fabricate(:distributor)
    @statement = Fabricate(:bank_statement, distributor: @distributor)
    @customer = Fabricate(:customer)
    @customers_ids = {}

    i = 0

    CSV.foreach(@statement.statement_file.path, :headers => true) do |row|
      if row['Amount'].to_i > 0
        @customers_ids["#{i}"] = @customer.id.to_s
        i+=1
      end
    end
  end

  specify {@statement.should be_valid}

  describe '#process_statement!' do
    it 'creates payments from a csv file'  do
      @statement.should_receive('create_payment!').exactly(@customers_ids.length).times
      @statement.process_statement! @customers_ids
    end

    context :associations do
      before :each do
        @statement.save!
        hash = {"0" => "1"}
        @statement.process_statement!(hash)
      end

      it 'sets a statement_id to the payments' do
        Payment.last.bank_statement_id.should == @statement.id
      end
    end
  end

  describe '#customer_remembers' do
    before :each do
      @statement.process_statement!(@customers_ids)
      @statement2 = Fabricate(:bank_statement, distributor: @distributor)
      @remembers = @statement2.customer_remembers
    end

    specify {@remembers.should_not be_nil}
  end
end
