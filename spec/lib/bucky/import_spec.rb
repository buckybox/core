require 'spec_helper'

describe Bucky::Import do
  context '#preprocess' do
    context 'should remove unneeded rows' do
      before(:all) do
        csv = CSV.generate do |rows|
          rows << Import::CSV_HEADERS
          rows << ['rubbish','45','more rubbish']
          rows << ['trash','65','more trash']
          rows << ['you can see me','for sure']
        end

        @parsed_csv = Import.preprocess(csv)
      end

      specify { expect(@parsed_csv).not_to match /(rubbish)|(45)/ }
      specify { expect(@parsed_csv).not_to match /(trash)|(65)/ }
      specify { expect(@parsed_csv).to match /you can see me/ }
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
    specify { expect(@customers.size).to eq(4) }

    context 'John' do
      before(:all) do
        @john = @customers.first
      end
      # values from Import::TEST_FILE, last check it is 'spec/support/test_upload_files/bucky_box.csv'
      specify { expect(@john.name).to eq('John Doe') }
      specify { expect(@john.number).to  eq('1121') }
      specify { expect(@john.email).to eq('jd@example.com') }
      specify { expect(@john.phone_1).to eq('0800 128 1231') }
      specify { expect(@john.phone_2).to eq('021 8167 7811') }
      specify { expect(@john.tags).to eq(['referral', 'discount2']) }
      specify { expect(@john.notes).to be_nil }
      specify { expect(@john.discount).to eq(0.2) }
      specify { expect(@john.account_balance).to eq(75.55) }
      specify { expect(@john.delivery_address_line_1).to eq('221 Old Porirua Rd') }
      specify { expect(@john.delivery_address_line_2).to be_nil }
      specify { expect(@john.delivery_suburb).to eq('Ngaio') }
      specify { expect(@john.delivery_city).to eq('Wellington') }
      specify { expect(@john.delivery_postcode).to be_nil }
      specify { expect(@john.delivery_service).to eq('CBD Van') }
      specify { expect(@john.delivery_instructions).to eq('Leave on deck, by door at side of house') }

      context :boxes do
        before(:all) do
          @boxes = @john.boxes
        end
        specify { expect(@boxes.size).to eq(3) }
        specify { expect(@boxes.collect(&:box_type)).to eq(['Standard Box', 'Medium Fruit Box', 'Large Mixed Box']) }
        specify { expect(@boxes.collect(&:dislikes)).to eq(['Onions',nil,nil]) }
        specify { expect(@boxes.collect(&:likes)).to eq([nil,nil,nil]) }
        specify { expect(@boxes.collect(&:delivery_frequency)).to eq(['weekly', 'single', 'fortnightly']) }
        specify { expect(@boxes.collect(&:delivery_days)).to eq(['Monday, Tuesday, Wednesday', '', 'Friday']) }
        specify { expect(@boxes.collect(&:next_delivery_date)).to eq(["21-Mar-2012", "26-Mar-2012", "30-Mar-2012"]) }
        specify { expect(@boxes.collect(&:extras_recurring?)).to eq([false, false, true]) }

        context :extras do
          before(:all) do
            @extras = @boxes.collect(&:extras).flatten.compact
          end
          specify { expect(@extras.size).to eq(6)}
          specify { expect(@extras.collect(&:name)).to eq(["Oronge Juice", "orga nic sugar", "eggs", "Orange Juice", "Orange Juice", "Organic Sugar"]) }
          specify { expect(@extras.collect(&:unit)).to eq(["600 ml", nil, nil, "600L", "1 L", nil]) }
          specify { expect(@extras.collect(&:count)).to eq([1, 2, 1, 3, 1, 2]) }
        end
      end
    end

    context 'Mary' do
      before(:all) do
        @mary = @customers[1]
      end
      # values from Import::TEST_FILE, last check it is 'spec/support/test_upload_files/bucky_box.csv'
      specify { expect(@mary.name).to eq('Mary Lamb') }
      specify { expect(@mary.number).to  eq('921') }
      specify { expect(@mary.email).to eq('ml@example.com') }
      specify { expect(@mary.phone_1).to eq('04 234 2342') }
      specify { expect(@mary.phone_2).to be_nil }
      specify { expect(@mary.tags).to eq([]) }
      specify { expect(@mary.notes).to be_nil }
      specify { expect(@mary.discount).to eq(0) }
      specify { expect(@mary.account_balance).to eq(0) }
      specify { expect(@mary.delivery_address_line_1).to eq('12 Hill Rd') }
      specify { expect(@mary.delivery_address_line_2).to be_nil }
      specify { expect(@mary.delivery_suburb).to eq('Aro Valley') }
      specify { expect(@mary.delivery_city).to eq('Wellington') }
      specify { expect(@mary.delivery_postcode).to be_nil }
      specify { expect(@mary.delivery_service).to eq('CBD Van') }
      specify { expect(@mary.delivery_instructions).to be_nil }

      context :boxes do
        before(:all) do
          @boxes = @mary.boxes
        end

        specify { expect(@boxes.size).to eq(1) }
        specify { expect(@boxes.first.box_type).to eq('Standard Box') }
        specify { expect(@boxes.first.dislikes).to be_nil }
        specify { expect(@boxes.first.likes).to be_nil }
        specify { expect(@boxes.first.delivery_frequency).to eq('weekly') }
        specify { expect(@boxes.first.delivery_days).to eq('Thursday') }
        specify { expect(@boxes.first.next_delivery_date).to eq("22-Mar-2012") }
        specify { expect(@boxes.collect(&:extras_recurring?)).to eq([false]) }

        context :extras do
          before(:all) do
            @extras = @boxes.collect(&:extras).flatten.compact
          end
          specify { expect(@extras.size).to eq(0)}
          specify { expect(@extras.collect(&:name)).to eq([]) }
          specify { expect(@extras.collect(&:unit)).to eq([]) }
          specify { expect(@extras.collect(&:count)).to eq([]) }
        end
      end
    end

    context 'William' do
      before(:all) do
        @will = @customers[2]
      end
      # values from Import::TEST_FILE, last check it is 'spec/support/test_upload_files/bucky_box.csv'
      specify { expect(@will.name).to eq('William Robberts') }
      specify { expect(@will.number).to  eq('321') }
      specify { expect(@will.email).to eq('wr@example.com') }
      specify { expect(@will.phone_1).to be_nil }
      specify { expect(@will.phone_2).to be_nil }
      specify { expect(@will.tags).to eq([]) }
      specify { expect(@will.notes).to eq('Very Touchy customer') }
      specify { expect(@will.discount).to eq(0.001) }
      specify { expect(@will.account_balance).to eq(0) }
      specify { expect(@will.delivery_address_line_1).to eq('89 Awarua St') }
      specify { expect(@will.delivery_address_line_2).to eq('Flat 3') }
      specify { expect(@will.delivery_suburb).to eq('Ngaio') }
      specify { expect(@will.delivery_city).to eq('Wellington') }
      specify { expect(@will.delivery_postcode).to eq('543') }
      specify { expect(@will.delivery_service).to eq('Rural Van') }
      specify { expect(@will.delivery_instructions).to eq('Door round back please.') }

      context :boxes do
        before(:all) do
          @boxes = @will.boxes
        end

        specify { expect(@boxes.size).to eq(1) }
        specify { expect(@boxes.first.box_type).to eq('Medium Fruit Box') }
        specify { expect(@boxes.first.dislikes).to eq('Carrots') }
        specify { expect(@boxes.first.likes).to eq('Apples') }
        specify { expect(@boxes.first.delivery_frequency).to eq('single') }
        specify { expect(@boxes.first.delivery_days).to eq('') }
        specify { expect(@boxes.first.next_delivery_date).to eq("21-Apr-2012") }
        specify { expect(@boxes.collect(&:extras_recurring?)).to eq([true]) }

        context :extras do
          before(:all) do
            @extras = @boxes.collect(&:extras).flatten.compact
          end
          specify { expect(@extras.size).to eq(1)}
          specify { expect(@extras.collect(&:name)).to eq(["Orgonic Sugar"]) }
          specify { expect(@extras.collect(&:unit)).to eq([nil]) }
          specify { expect(@extras.collect(&:count)).to eq([2]) }
        end
      end
    end
  end
end
