require 'spec_helper'

describe LineItem do
  let(:line_item)    { Fabricate(:line_item) }
  let(:distributor)  { line_item.distributor }
  let(:exclusion)    { Fabricate(:exclusion, line_item: line_item) }
  let(:substitution) { Fabricate(:substitution, line_item: line_item) }

  specify { expect(line_item).to be_valid }

  describe '.from_list' do
    context :invalid do
      specify { expect(LineItem.from_list(distributor, '')).to be false }
    end

    context :valid do
      before do
        @old_item_name = 'Red Grapes'

        # as an existing list item
        line_item.name = @old_item_name
        line_item.save

        @text = "oranges\nKiwi fruit\napples\npears\nApples"
      end

      specify { expect { LineItem.from_list(distributor, @text) }.to change(distributor.line_items(true), :count).from(1).to(5) }

      specify { expect(LineItem.from_list(distributor, @text).map(&:name).include?(@old_item_name)).to be true }
      specify { expect(LineItem.from_list(distributor, @text).map(&:name).include?('Apples')).to be true }
      specify { expect(LineItem.from_list(distributor, @text).map(&:name).include?('Oranges')).to be true }
      specify { expect(LineItem.from_list(distributor, @text).map(&:name).include?('Pears')).to be true }
      specify { expect(LineItem.from_list(distributor, @text).map(&:name).include?('Kiwi Fruit')).to be true }
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
        before { LineItem.bulk_update(distributor, { line_item.id => { name: '' } }) }

        specify { expect(LineItem.find_by_id(line_item.id)).to be_nil }
        specify { expect(Exclusion.find_by_id(exclusion.id)).to be_nil }
        specify { expect(Substitution.find_by_id(substitution.id)).to be_nil }
      end

      context 'changed name' do
        before do
          @new_name = 'Chinese gooseberry'
          @new_line_item = Fabricate(:line_item, name: @new_name)
          allow(LineItem).to receive(:where) { double(first_or_create: @new_line_item) } # FIXME: brittle stubbing

          LineItem.bulk_update(distributor, { line_item.id => { name: @new_name } })
        end

        specify { expect(@new_line_item.name).to eq @new_name.titleize }
        specify { expect(@new_line_item.id).to eq exclusion.reload.line_item_id }
        specify { expect(@new_line_item.id).to eq substitution.reload.line_item_id }
      end

      context 'same name' do
        before { LineItem.bulk_update(distributor, { line_item.id => { name: line_item.name } }) }

        specify { expect(line_item.reload.persisted?).to be true }
        specify { expect(line_item.id).to eq exclusion.line_item_id }
        specify { expect(line_item.id).to eq substitution.line_item_id }
      end

      specify { expect { LineItem.bulk_update(distributor, nil) }.to_not raise_error }
    end

    describe '.move_exclustions_and_substitutions!' do
      before do
        @new_line_item = Fabricate(:line_item)
        LineItem.move_exclustions_and_substitutions!(line_item, @new_line_item)
      end

      specify { expect(LineItem.find_by_id(line_item.id)).to be_nil }
      specify { expect(@new_line_item.exclusions(true).to_a).to eq [exclusion] }
      specify { expect(@new_line_item.substitutions(true).to_a).to eq [substitution] }
    end
  end
end
