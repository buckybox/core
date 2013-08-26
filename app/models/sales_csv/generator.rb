module SalesCsv
  class Generator
    def initialize(data, options = {})
      @data = data
    end

    def generate
      CSV.generate do |csv|
        add_headers(csv)
        add_data(csv)
      end
    end

  protected

    attr_reader :data
    attr_reader :row_generator

    def add_headers(csv)
      csv << csv_headers
    end

    def add_data(csv)
      data.each do |data_row|
        csv_row = row_generator.new(data_row)
        csv << csv_row.generate
      end
    end

    def csv_headers
      [
        'Delivery Service',
        'Delivery Sequence Number',
        'Delivery Pickup Point Name',
        'Order Number',
        'Package Number',
        'Delivery Date',
        'Customer Number',
        'Customer First Name',
        'Customer Last Name',
        'Customer Phone',
        'New Customer',
        'Delivery Address Line 1',
        'Delivery Address Line 2',
        'Delivery Address Suburb',
        'Delivery Address City',
        'Delivery Address Postcode',
        'Delivery Note',
        'Box Contents Short Description',
        'Box Type',
        'Box Likes',
        'Box Dislikes',
        'Box Extra Line Items',
        'Price',
        'Bucky Box Transaction Fee',
        'Total Price',
        'Customer Email',
        'Customer Special Preferences',
        'Package Status',
        'Delivery Status',
      ]
    end
  end
end
