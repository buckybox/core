module SalesCsv
  class RowGenerator
    def initialize(data)
      @data = data
    end

    def generate
      [
        delivery_route,
        delivery_sequence_number,
        delivery_pickup_point_name,
        order_number,
        package_number,
        delivery_date,
        customer_number,
        customer_first_name,
        customer_last_name,
        customer_phone,
        new_customer,
        delivery_address_line_1,
        delivery_address_line_2,
        delivery_address_suburb,
        delivery_address_city,
        delivery_address_postcode,
        delivery_note,
        box_contents_short_description,
        box_type,
        box_likes,
        box_dislikes,
        box_extra_line_items,
        price,
        bucky_box_transaction_fee,
        total_price,
        customer_email,
        customer_special_preferences,
        package_status,
        delivery_status,
      ]
    end

  protected

    attr_reader :data

    def customer
      @customer ||= order.customer
    end

    def delivery_route
      order.route_name
    end

    def delivery_sequence_number
      delivery.formated_delivery_number if delivery
    end

    #NOTE: Keeping this due to legacy CSV convention but nothing in system for it yet
    def delivery_pickup_point_name
      nil
    end

    def order_number
      order.id
    end

    def package_number
      package.id
    end

    def delivery_date
      package.date.strftime("%-d %b %Y")
    end

    def customer_number
      customer.number
    end

    def customer_first_name
      customer.first_name
    end

    def customer_last_name
      customer.last_name
    end

    def customer_phone
      address.phone_1
    end

    def new_customer
      customer.new? ? 'NEW' : nil
    end

    def delivery_address_line_1
      address.address_1
    end

    def delivery_address_line_2
      address.address_2
    end

    def delivery_address_suburb
      address.suburb
    end

    def delivery_address_city
      address.city
    end

    def delivery_address_postcode
      address.postcode
    end

    def delivery_note
      address.delivery_note
    end

    def box_contents_short_description
      archived.short_code
    end

    def box_type
      archived.archived_box_name
    end

    def box_likes
      archived.archived_substitutions
    end

    def box_dislikes
      archived.archived_exclusions
    end

    def box_extra_line_items
      archived.extras_description
    end

    def price
      archived.price
    end

    def bucky_box_transaction_fee
      archived.archived_consumer_delivery_fee
    end

    def total_price
      archived.total_price
    end

    def customer_email
      customer.email
    end

    def customer_special_preferences
      customer.special_order_preference
    end

    def package_status
      package.status
    end

    def delivery_status
      delivery.status
    end
  end
end
