require 'spec_helper'

describe CustomerDecorator do
  let(:customer) { Fabricate(:customer).decorate }

  describe "#dynamic_tags" do
    specify { expect(customer.dynamic_tags).to be_a Hash }

    context "with a negative balance" do
      before { customer.stub(:account_balance) { CrazyMoney.new(-1) } }

      specify { expect(customer.dynamic_tags).to have_key "negative-balance" }
    end

    context "with a positive balance" do
      before { customer.stub(:account_balance) { CrazyMoney.new(1) } }

      specify { expect(customer.dynamic_tags).to_not have_key "negative-balance" }
    end
  end

  describe "#next_delivery_summary" do
    context "with no upcoming deliveries" do
      specify do
        expect(customer.next_delivery_summary).to eq "(no upcoming deliveries)"
      end
    end

    context "with one box without extras" do
      before do
        order = Fabricate(:order, customer: customer)
        customer.update_next_occurrence

        @date = order.next_occurrence.strftime("%A, %d %b %Y")
        @box = order.box
      end

      specify do
        expect(customer.next_delivery_summary).to eq "#{@date}\n#{@box.name}"
      end
    end

    context "with two boxes with extras" do
      before do
        order = Fabricate(:order, customer: customer)
        order_with_extras = Fabricate(:order, customer: customer)
        @extras = Fabricate.times(2, :order_extra, order: order_with_extras)
        customer.update_next_occurrence

        @date = order.next_occurrence.strftime("%A, %d %b %Y")
        @box = order.box
        @box_with_extras = order_with_extras.box
        @box_with_extras.update_attributes(name: "Box 9999") # make sure it's the last box since boxes are sorted alphabetically
      end

      specify do
        expect(customer.next_delivery_summary).to eq "#{@date}\n#{@box.name}\n#{@box_with_extras.name} - #{@extras.first.name} single, #{@extras.second.name} single"
      end
    end
  end
end
