module DeliveryCsv

  module ClassMethods
    def csv_headers
      [
        'Delivery Route', 'Delivery Sequence Number', 'Delivery Pickup Point Name',
        'Order Number', 'Package Number', 'Delivery Date', 'Customer Number', 'Customer First Name',
        'Customer Last Name', 'Customer Phone', 'New Customer', 'Delivery Address Line 1', 'Delivery Address Line 2',
        'Delivery Address Suburb', 'Delivery Address City', 'Delivery Address Postcode', 'Delivery Note',
        'Box Contents Short Description', 'Box Type', 'Box Likes', 'Box Dislikes', 'Box Extra Line Items',
        'Price', 'Bucky Box Transaction Fee', 'Total Price', 'Customer Email', 'Customer Special Preferences'
      ]
    end
  end

  def to_csv
    # At the moment a package only has one delivery. This will change with recheduling, repacking and the 
    # refactor. Was included because we thought we were going to do rescheduling sooner then we did.
    delivery = self.is_a?(Delivery) ? self : deliveries.ordered.first
    [
      route.name,
      ((!delivery.nil? && delivery.delivery_number) ? ("%03d" % delivery.delivery_number) : nil),
      nil,
      order.id,
      id,
      date.strftime("%-d %b %Y"),
      customer.number,
      customer.first_name,
      customer.last_name,
      address.phone_1,
      (customer.new? ? 'NEW' : nil),
      archived_address_details.address_1,
      archived_address_details.address_2,
      archived_address_details.suburb,
      archived_address_details.city,
      archived_address_details.postcode,
      archived_address_details.delivery_note,
      order.string_sort_code,
      archived_box_name,
      archived_substitutions,
      archived_exclusions,
      extras_description,
      price,
      archived_consumer_delivery_fee,
      total_price,
      customer.email,
      customer.special_order_preference
    ]
  end

end
