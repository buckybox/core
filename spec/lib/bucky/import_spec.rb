require 'spec_helper'

describe Import do
  context '#preprocess' do
    before do
      csv = CSV.generate do |csv|
        csv << Import::CSV_HEADERS
        csv << ['rubbish','45','more rubbish']
        csv << ['trash','65','more trash']
        csv << ['you can see me','for sure']
      end
      @parsed_csv = Import.preprocess(csv)
    end

    specify { @parsed_csv.should_not match /(rubbish)|(45)/ }
    specify { @parsed_csv.should_not match /(trash)|(65)/ }
    specify { @parsed_csv.should match /you can see me/ }
  end

  context '#parse' do
    before(:all) do
      @customers = Import.parse(File.read(Import::TEST_FILE), Distributor.new) # Bucky::Import::Customer
    end
    specify { @customers.size.should eq(4) }
    
    context 'John' do
      before(:all) do
        @john = @customers.first
      end
      # values from Import::TEST_FILE, last check it is 'spec/support/test_upload_files/bucky_box.csv'
      specify { @john.name.should eq('John Doe') }
      specify { @john.number.should  eq('1121') }
      specify { @john.email.should eq('jd@example.com') }
      specify { @john.phone_1.should eq('0800 128 1231') }
      specify { @john.phone_2.should eq('021 8167 7811') }
      specify { @john.tags.should eq(['referral', 'discount2']) }
      specify { @john.notes.should be_nil }
      specify { @john.discount.should eq(0.2) }
      specify { @john.account_balance.should eq(75.55) }
      specify { @john.delivery_address_line_1.should eq('221 Old Porirua Rd') }
      specify { @john.delivery_address_line_2.should be_nil }
      specify { @john.delivery_suburb.should eq('Ngaio') }
      specify { @john.delivery_city.should eq('Wellington') }
      specify { @john.delivery_postcode.should be_nil }
      specify { @john.delivery_route.should eq('CBD Van') }
      specify { @john.delivery_instructions.should eq('Leave on deck, by door at side of house') }

      context :boxes do
        before(:all) do
          @boxes = @john.boxes
        end
        specify { @boxes.size.should eq(3) }
        specify { @boxes.collect(&:box_type).should eq(['Standard Box', 'Medium Fruit Box', 'Large Mixed Box']) }
        specify { @boxes.collect(&:dislikes).should eq(['Onions',nil,nil]) }
        specify { @boxes.collect(&:likes).should eq([nil,nil,nil]) }
        specify { @boxes.collect(&:delivery_frequency).should eq(['Weekly', 'Single', 'Fortnightly']) }
        specify { @boxes.collect(&:delivery_days).should eq(['Monday, Tuesday, Wednesday', '', 'Friday']) }
        specify { @boxes.collect(&:next_delivery_date).should eq(["21-Mar-2012", "26-Mar-2012", "30-Mar-2012"]) }
      end
    end

    context 'Mary' do
      before(:all) do
        @mary = @customers[1]
      end
      # values from Import::TEST_FILE, last check it is 'spec/support/test_upload_files/bucky_box.csv'
      specify { @mary.name.should eq('Mary Lamb') }
      specify { @mary.number.should  eq('921') }
      specify { @mary.email.should eq('ml@example.com') }
      specify { @mary.phone_1.should eq('04 234 2342') }
      specify { @mary.phone_2.should be_nil }
      specify { @mary.tags.should eq([]) }
      specify { @mary.notes.should be_nil }
      specify { @mary.discount.should eq(0) }
      specify { @mary.account_balance.should eq(0) }
      specify { @mary.delivery_address_line_1.should eq('12 Hill Rd') }
      specify { @mary.delivery_address_line_2.should be_nil }
      specify { @mary.delivery_suburb.should eq('Aro Valley') }
      specify { @mary.delivery_city.should eq('Wellington') }
      specify { @mary.delivery_postcode.should be_nil }
      specify { @mary.delivery_route.should eq('CBD Van') }
      specify { @mary.delivery_instructions.should be_nil }

      context :boxes do
        before(:all) do
          @boxes = @mary.boxes
        end

        specify { @boxes.size.should eq(1) }
        specify { @boxes.first.box_type.should eq('Standard Box') }
        specify { @boxes.first.dislikes.should be_nil }
        specify { @boxes.first.likes.should be_nil }
        specify { @boxes.first.delivery_frequency.should eq('Weekly') }
        specify { @boxes.first.delivery_days.should eq('Thursday') }
        specify { @boxes.first.next_delivery_date.should eq("22-Mar-2012") }
      end
      
    end
  end
end
