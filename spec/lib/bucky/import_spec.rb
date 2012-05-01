require 'spec_helper'

describe Bucky::Import do
  context '#preprocess' do
    context 'should remove unneeded rows' do
      before(:all) do
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

    context 'check headers' do
      let(:csv_with_less_headers) do
        CSV.generate do |csv|
          csv << Import::CSV_HEADERS[0..-2]
          csv << ['rubbish','45','more rubbish']
          csv << ['trash','65','more trash']
          csv << ['you can see me','for sure']
        end
      end
      specify { expect{ Import.preprocess(csv_with_less_headers)}.to raise_error }

      let(:csv_with_more_headers) do
        CSV.generate do |csv|
          csv << (Import::CSV_HEADERS + ["Im not meant to be here"])
          csv << ['rubbish','45','more rubbish']
          csv << ['trash','65','more trash']
          csv << ['you can see me','for sure']
        end
      end
      specify { expect{ Import.preprocess(csv_with_more_headers)}.to raise_error }

      let(:csv_with_wrong_headers) do
        CSV.generate do |csv|
          headers = Import::CSV_HEADERS.clone
          headers[3] = "Wrong Header"
          csv << headers
          csv << ['rubbish','45','more rubbish']
          csv << ['trash','65','more trash']
          csv << ['you can see me','for sure']
        end
      end
      specify { expect{ Import.preprocess(csv_with_wrong_headers)}.to raise_error }
    end
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
        specify { @boxes.collect(&:delivery_frequency).should eq(['weekly', 'single', 'fortnightly']) }
        specify { @boxes.collect(&:delivery_days).should eq(['Monday, Tuesday, Wednesday', '', 'Friday']) }
        specify { @boxes.collect(&:next_delivery_date).should eq(["21-Mar-2012", "26-Mar-2012", "30-Mar-2012"]) }
        specify { @boxes.collect(&:extras_recurring?).should eq([false, false, true]) }

        context :extras do
          before(:all) do
            @extras = @boxes.collect(&:extras).flatten.compact
          end
          specify { @extras.size.should eq(6)}
          specify { @extras.collect(&:name).should eq(["Oronge Juice", "orga nic sugar", "eggs", "Orange Juice", "Orange Juice", "Organic Sugar"]) }
          specify { @extras.collect(&:unit).should eq(["600 ml", nil, nil, "600L", "1 L", nil]) }
          specify { @extras.collect(&:count).should eq([1, 2, 1, 3, 1, 2]) }
        end
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
        specify { @boxes.first.delivery_frequency.should eq('weekly') }
        specify { @boxes.first.delivery_days.should eq('Thursday') }
        specify { @boxes.first.next_delivery_date.should eq("22-Mar-2012") }
        specify { @boxes.collect(&:extras_recurring?).should eq([false]) }

        context :extras do
          before(:all) do
            @extras = @boxes.collect(&:extras).flatten.compact
          end
          specify { @extras.size.should eq(0)}
          specify { @extras.collect(&:name).should eq([]) }
          specify { @extras.collect(&:unit).should eq([]) }
          specify { @extras.collect(&:count).should eq([]) }
        end
      end
    end

    context 'William' do
      before(:all) do
        @will = @customers[2]
      end
      # values from Import::TEST_FILE, last check it is 'spec/support/test_upload_files/bucky_box.csv'
      specify { @will.name.should eq('William Robberts') }
      specify { @will.number.should  eq('321') }
      specify { @will.email.should eq('wr@example.com') }
      specify { @will.phone_1.should be_nil }
      specify { @will.phone_2.should be_nil }
      specify { @will.tags.should eq([]) }
      specify { @will.notes.should eq('Very Touchy customer') }
      specify { @will.discount.should eq(0.001) }
      specify { @will.account_balance.should eq(0) }
      specify { @will.delivery_address_line_1.should eq('89 Awarua St') }
      specify { @will.delivery_address_line_2.should eq('Flat 3') }
      specify { @will.delivery_suburb.should eq('Ngaio') }
      specify { @will.delivery_city.should eq('Wellington') }
      specify { @will.delivery_postcode.should eq('543') }
      specify { @will.delivery_route.should eq('Rural Van') }
      specify { @will.delivery_instructions.should eq('Door round back please.') }

      context :boxes do
        before(:all) do
          @boxes = @will.boxes
        end

        specify { @boxes.size.should eq(1) }
        specify { @boxes.first.box_type.should eq('Medium Fruit Box') }
        specify { @boxes.first.dislikes.should eq('Carrots') }
        specify { @boxes.first.likes.should eq('Apples') }
        specify { @boxes.first.delivery_frequency.should eq('single') }
        specify { @boxes.first.delivery_days.should eq('') }
        specify { @boxes.first.next_delivery_date.should eq("21-Apr-2012") }
        specify { @boxes.collect(&:extras_recurring?).should eq([true]) }

        context :extras do
          before(:all) do
            @extras = @boxes.collect(&:extras).flatten.compact
          end
          specify { @extras.size.should eq(1)}
          specify { @extras.collect(&:name).should eq(["Orgonic Sugar"]) }
          specify { @extras.collect(&:unit).should eq([nil]) }
          specify { @extras.collect(&:count).should eq([2]) }
        end
      end
    end
  end
end
