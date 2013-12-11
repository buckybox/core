require 'spec_helper'

describe CustomerDecorator do
  let(:customer) { Fabricate(:customer).decorate }

  describe "#next_delivery_summary" do
    context "with no upcoming deliveries" do
      specify do
        expect(customer.next_delivery_summary).to eq "(no upcoming delivery)"
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
      end

      specify do
        expect(customer.next_delivery_summary).to eq "#{@date}\n#{@box.name}\n#{@box_with_extras.name} - 1x #{@extras.first.name} single, 1x #{@extras.second.name} single"
      end
    end
  end
end
