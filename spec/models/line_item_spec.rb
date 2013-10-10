require 'spec_helper'

describe LineItem do
  let(:line_item)    { Fabricate(:line_item) }
  let(:distributor)  { line_item.distributor }
  let(:exclusion)    { Fabricate(:exclusion, line_item: line_item) }
  let(:substitution) { Fabricate(:substitution, line_item: line_item) }

  specify { line_item.should be_valid }

  describe '.from_list' do
    context :invalid do
      specify { LineItem.from_list(distributor, '').should be_false }
    end

    context :valid do
      before do
        @old_item_name = 'Red Grapes'

        # as an existing list item
        line_item.name = @old_item_name
        line_item.save

        @text = "oranges\nKiwi fruit\napples\npears\nApples"
      end

      specify { expect{ LineItem.from_list(distributor, @text) }.to change(distributor.line_items(true), :count).from(1).to(5) }

      specify { LineItem.from_list(distributor, @text).map(&:name).include?(@old_item_name).should be_true }
      specify { LineItem.from_list(distributor, @text).map(&:name).include?('Apples').should be_true }
      specify { LineItem.from_list(distributor, @text).map(&:name).include?('Oranges').should be_true }
      specify { LineItem.from_list(distributor, @text).map(&:name).include?('Pears').should be_true }
      specify { LineItem.from_list(distributor, @text).map(&:name).include?('Kiwi Fruit').should be_true }
    end
  end

  context 'changing line items' do
    before do
      line_item.save
      exclusion.save
      substitution.save
    end

    describe '.bulk_update' do
      context 'blank name' do
        before { LineItem.bulk_update(distributor, { line_item.id => {name: ''} }) }

        specify { LineItem.find_by_id(line_item.id).should be_nil }
        specify { Exclusion.find_by_id(exclusion.id).should be_nil }
        specify { Substitution.find_by_id(substitution.id).should be_nil }
      end

      context 'changed name' do
        before do
          @new_name = 'Chinese gooseberry'
          @new_line_item = Fabricate(:line_item, name: @new_name)
          LineItem.stub(:find_or_create_by_name).and_return(@new_line_item)

          LineItem.bulk_update(distributor, { line_item.id => {name: @new_name} })
        end

        specify { @new_line_item.name.should == @new_name.titleize }
        specify { @new_line_item.id.should == exclusion.reload.line_item_id }
        specify { @new_line_item.id.should == substitution.reload.line_item_id }
      end

      context 'same name' do
        before { LineItem.bulk_update(distributor, { line_item.id => {name: line_item.name} }) }

        specify { line_item.reload.persisted?.should be_true }
        specify { line_item.id.should == exclusion.line_item_id }
        specify { line_item.id.should == substitution.line_item_id }
      end

      specify { expect{LineItem.bulk_update(distributor, nil)}.to_not raise_error}
    end

    describe '.move_exclustions_and_substitutions!' do
      before do
        @new_line_item = Fabricate(:line_item)
        LineItem.move_exclustions_and_substitutions!(line_item, @new_line_item)
      end

      specify { LineItem.find_by_id(line_item.id).should be_nil }
      specify { @new_line_item.exclusions(true).to_a.should == [exclusion] }
      specify { @new_line_item.substitutions(true).to_a.should == [substitution] }
    end
  end

  context 'line item customer counts' do
    describe '#exclusions_count_by_customer' do
      before do
        e1 = Fabricate(:exclusion)
        e1.stub_chain(:customer, :id).and_return(1)
        e2 = Fabricate(:exclusion)
        e2.stub_chain(:customer, :id).and_return(2)
        e3 = Fabricate(:exclusion)
        e3.stub_chain(:customer, :id).and_return(1)

        line_item.stub_chain(:exclusions, :active).and_return([e1, e2, e3])
      end

      specify { line_item.exclusions_count_by_customer.should == 2 }
    end

    describe '#substitution_count_by_customer' do
      before do
        s1 = Fabricate(:substitution)
        s1.stub_chain(:customer, :id).and_return(1)
        s2 = Fabricate(:substitution)
        s2.stub_chain(:customer, :id).and_return(2)
        s3 = Fabricate(:substitution)
        s3.stub_chain(:customer, :id).and_return(1)

        line_item.stub_chain(:substitutions, :active).and_return([s1, s2, s3])
      end

      specify { line_item.substitution_count_by_customer.should == 2 }
    end
  end
end
