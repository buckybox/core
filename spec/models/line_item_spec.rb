require 'spec_helper'

describe LineItem do
  let(:line_item) { Fabricate.build(:line_item) }
  let(:distributor) { line_item.distributor }

  specify { line_item.should be_valid }

  describe '.from_list!' do
    context :invalid do
      specify { LineItem.from_list!(distributor, '').should be_false }
    end

    context :valid do
      before do
        @old_item_name = 'mice'

        # as an existing list item
        line_item.name = @old_item_name
        line_item.save

        @text = "oranges\nKiwi fruit\napples\npears\nApples"
      end

      specify { expect{ LineItem.from_list!(distributor, @text) }.should change(distributor.line_items(true), :count).from(1).to(4) }

      specify { LineItem.from_list!(distributor, @text).map(&:name).include?(@old_item_name).should_not be_true }
      specify { LineItem.from_list!(distributor, @text).map(&:name).include?('Apples').should be_true }
      specify { LineItem.from_list!(distributor, @text).map(&:name).include?('Oranges').should be_true }
      specify { LineItem.from_list!(distributor, @text).map(&:name).include?('Pears').should be_true }
      specify { LineItem.from_list!(distributor, @text).map(&:name).include?('Kiwi Fruit').should be_true }
    end
  end

  describe '.to_list' do
    before do
      @distributor = Fabricate(:distributor)
      %w(oranges apples pears kiwi\ fruit).each { |name| Fabricate(:line_item, name: name, distributor: @distributor) }
    end

    specify { LineItem.to_list(@distributor).should == "Apples\nKiwi Fruit\nOranges\nPears" }
  end

  context 'line item customer counts' do
    describe '#exclusions_count_by_customer' do
      before do
        e1 = Fabricate.build(:exclusion)
        e1.stub_chain(:customer, :id).and_return(1)
        e2 = Fabricate.build(:exclusion)
        e2.stub_chain(:customer, :id).and_return(2)
        e3 = Fabricate.build(:exclusion)
        e3.stub_chain(:customer, :id).and_return(1)

        line_item.stub(:exclusions).and_return([e1, e2, e3])
      end

      specify { line_item.exclusions_count_by_customer.should == 2 }
    end

    describe '#substitution_count_by_customer' do
      before do
        s1 = Fabricate.build(:substitution)
        s1.stub_chain(:customer, :id).and_return(1)
        s2 = Fabricate.build(:substitution)
        s2.stub_chain(:customer, :id).and_return(2)
        s3 = Fabricate.build(:substitution)
        s3.stub_chain(:customer, :id).and_return(1)

        line_item.stub(:substitutions).and_return([s1, s2, s3])
      end

      specify { line_item.substitution_count_by_customer.should == 2 }
    end
  end
end
