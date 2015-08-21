require 'spec_helper'

describe CustomerDecorator do
  let(:customer) { Fabricate(:customer).decorate }

  describe "#next_delivery_summary" do
    context "with no upcoming deliveries" do
      specify do
        expect(customer.next_delivery_summary).to eq "(no upcoming deliveries)"
      end
    end

    context "with one box without extras" do
      before do
        order = Fabricate(:order, account: customer.account)
        customer.update_next_occurrence

        @date = order.next_occurrence.strftime("%A, %d %b %Y")
        @box = order.box
      end

      specify do
        expect(customer.next_delivery_summary).to eq "#{@date}\n* #{@box.name}"
      end
    end

    context "with two boxes with extras" do
      before do
        order = Fabricate(:order, account: customer.account)
        order_with_extras = Fabricate(:order, account: customer.account)
        @extras = [
          Fabricate(:order_extra, order: order_with_extras),
          Fabricate(:order_extra, order: order_with_extras, count: 2),
        ]
        customer.update_next_occurrence

        @date = order.next_occurrence.strftime("%A, %d %b %Y")
        @box = order.box
        @box_with_extras = order_with_extras.box
        @box_with_extras.update_attributes(name: "Box 9999") # make sure it's the last box since boxes are sorted alphabetically
      end

      specify do
        expect(customer.next_delivery_summary).to eq "#{@date}\n* #{@box.name}\n* #{@box_with_extras.name} <em>with additional extra items of</em>:\n&nbsp;&nbsp;&nbsp;- 1x #{@extras.first.name} (single)\n&nbsp;&nbsp;&nbsp;- 2x #{@extras.second.name} (single)"
      end
    end
  end
end
