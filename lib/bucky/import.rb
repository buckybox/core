module Bucky
  class Import
    require 'csv' # Ruby's 1.9 CSV Lib
    require 'active_model'

    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/bucky_box.csv"))

    CSV_HEADERS = [
      CUSTOMER_NUMBER          = "Customer Number",
      CUSTOMER_FIRST_NAME      = "Customer First Name",
      CUSTOMER_LAST_NAME       = "Customer Last Name",
      CUSTOMER_EMAIL           = "Customer Email",
      CUSTOMER_PHONE_1         = "Customer Phone 1",
      CUSTOMER_PHONE_2         = "Customer Phone 2",
      CUSTOMER_TAGS            = "Customer Tags",
      CUSTOMER_NOTES           = "Customer Notes",
      CUSTOMER_DISCOUNT        = "Customer Discount",
      CUSTOMER_ACCOUNT_BALANCE = "Customer Account Balance",
      PAYMENT_TYPE             = "Payment Type",
      PAYMENT_TOKEN            = "Payment Token",
      DELIVERY_ADDRESS_LINE_1  = "Delivery Address Line 1",
      DELIVERY_ADDRESS_LINE_2  = "Delivery Address Line 2",
      DELIVERY_SUBURB          = "Delivery Suburb",
      DELIVERY_CITY            = "Delivery City",
      DELIVERY_POST_CODE_ZIP   = "Delivery Post Code / ZIP",
      DELIVERY_ROUTE           = "Delivery Route",
      DELIVERY_INSTRUCTIONS    = "Delivery Instructions",
      BOX_TYPE                 = "Box Type",
      DISLIKES                 = "Dislikes",
      LIKES                    = "Likes",
      DELIVERY_FREQUENCY       = "Delivery Frequency",
      DELIVERY_DAYS            = "Delivery Day(s)",
      NEXT_DELIVERY_DATE       = "Next Delivery Date"
    ]

    @@verbosity = :none

    def self.parse(csv_input, distributor)
      customers = []
      customer = nil

      CSV.parse(preprocess(csv_input), headers: true) do |row|
        customer_number = row[CUSTOMER_NUMBER]

        if customer.nil? # Start us off with the first row
          customer = customer_from_row(row, distributor)
        elsif customer.number == customer_number # Still on the same customer, must have more boxes, add them
          add_box_to_customer(row, customer, distributor)
        elsif customer.number != customer_number # No more boxes for that customer, move onto next one BUT check last one is valid first
          log "CUSTOMER"
          log "Customer #{customer.name} is #{customer.valid? ? "valid" : "invalid because #{customer.errors.full_messages.join(', ')}"}"
          raise "Customer #{customer.name} is invalid because #{customer.errors.full_messages.join(', ')}" unless customer.valid?

          customers << customer
          customer = customer_from_row(row, distributor)
        end
      end

      customers << customer # Last customer

      return customers
    end

    def self.customer_from_row(row, distributor)
      customer = Customer.new

      customer.distributor             = distributor
      customer.number                  = row[CUSTOMER_NUMBER]
      customer.first_name              = row[CUSTOMER_FIRST_NAME]
      customer.last_name               = row[CUSTOMER_LAST_NAME]
      customer.email                   = row[CUSTOMER_EMAIL]
      customer.phone_1                 = row[CUSTOMER_PHONE_1]
      customer.phone_2                 = row[CUSTOMER_PHONE_2]
      customer.notes                   = row[CUSTOMER_NOTES]
      customer.discount                = row[CUSTOMER_DISCOUNT].gsub('%','').to_f / 100.0 unless row[CUSTOMER_DISCOUNT].blank?
      customer.account_balance         = row[CUSTOMER_ACCOUNT_BALANCE].to_f
      customer.delivery_address_line_1 = row[DELIVERY_ADDRESS_LINE_1]
      customer.delivery_address_line_2 = row[DELIVERY_ADDRESS_LINE_2]
      customer.delivery_suburb         = row[DELIVERY_SUBURB]
      customer.delivery_city           = row[DELIVERY_CITY]
      customer.delivery_postcode       = row[DELIVERY_POST_CODE_ZIP]
      customer.delivery_route          = row[DELIVERY_ROUTE]
      customer.delivery_instructions   = row[DELIVERY_INSTRUCTIONS]

      tags = row[CUSTOMER_TAGS]

      if tags.present?
        tags.split(",").collect(&:strip).each do |tag|
          customer.add_tag(tag)
        end
      end

      add_box_to_customer(row, customer, distributor)

      return customer
    end

    def self.add_box_to_customer(row, customer, distributor)
      box = box_from_row(row)
      customer.add_box(box)

      return customer
    end

    def self.box_from_row(row)
      box = Box.new

      box.box_type           = row[BOX_TYPE]
      box.dislikes           = row[DISLIKES]
      box.likes              = row[LIKES]
      box.delivery_frequency = row[DELIVERY_FREQUENCY].downcase if row[DELIVERY_FREQUENCY].is_a?(String)
      box.delivery_days      = row[DELIVERY_DAYS]
      box.next_delivery_date = row[NEXT_DELIVERY_DATE]

      log("BOX")
      log("Box #{box.box_type} is #{box.valid? ? "valid" : "invalid because #{box.errors.full_messages.join(', ')}"}")
      raise ("Box #{box.box_type} is invalid because #{box.errors.full_messages.join(', ')}") unless box.valid?

      return box
    end

    # Strip blank rows and get into a consistent state
    # Exclude Rows is the non-blank rows which need to be ignored when parsing
    # the CSV file.
    EXCLUDE_ROWS = [1,2] # 0 is the header row
    def self.preprocess(csv_input)
      csv_string = CSV.generate do |csv|
        row_number = 0

        CSV.parse(csv_input, headers: false) do |row|
          # Check Headers match expectations of defined format
          if row_number == 0
            # Check all expected headers are spelt correctly and exist
            problems = []

            match = CSV_HEADERS.all? do |header|
              pass = row.include? header 
              problems << header unless pass
              pass
            end

            throw "CSV Headers/Titles was expected to have #{problems.collect{|p| "'#{p}'"}.join(', ')} but only found #{row.collect{|p| "'#{p}'"}.join(", ")}." unless match

            # Check the number of headers match the expected (don't want there to be more than expected
            expected_header_count = CSV_HEADERS.size
            actual_header_count = row.size

            throw "Expected #{expected_header_count} Headers/Titles but there was #{actual_header_count}" unless expected_header_count == actual_header_count
          end

          if EXCLUDE_ROWS.include?(row_number)
            log "EXCLUDING ROW #{row_number} which contains"
            log "="*80
            log row.join(", ")
            log "="*80
          else
            csv << row
          end

          row_number += 1
        end

      end

      log csv_string

      return csv_string
    end

    def self.test
      parse File.read(TEST_FILE), Distributor.new
    end

    class Customer
      include ActiveModel::Validations

      DATA_FIELDS = [:number, :first_name, :last_name, :email, :phone_1, :phone_2,
        :notes, :discount, :account_balance, :delivery_address_line_1,
        :delivery_address_line_2, :delivery_suburb, :delivery_city, :delivery_postcode,
        :delivery_route, :delivery_instructions]

      attr_accessor *DATA_FIELDS
      attr_accessor :distributor, :boxes, :tags

      validates_presence_of :number, :first_name, :email, :delivery_address_line_1,
        :delivery_suburb, :delivery_city
      validates_numericality_of :number, greater_than: 0
      validates_numericality_of :discount, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0
      #validate :uniqueness_of_number #Customer import will find or create based on number, left here to remind why

      @@previous_numbers = []

      def number=(n)
        @@previous_numbers << n
        @number = n
      end

      def add_box(box)
        self.boxes ||= []
        self.boxes << box
      end

      def add_tag(tag)
        @tags ||= []
        @tags << tag
      end

      def name
        [first_name, last_name].join(" ")
      end

      def tags
        @tags || []
      end

      def discount
        @discount || 0
      end

      def account_balance
        @account_balance || 0
      end

      def to_s
        instance_variables.inject({}) do |result, element|
          result.merge(element.to_sym => self.send(element.to_s.gsub('@','')))
        end
      end

      def uniqueness_of_number
        unless distributor.customers.where(number: number).count.zero?
          errors.add(:number, "is not unique") 
        end
      end
    end

    class Box
      include ActiveModel::Validations

      validates_inclusion_of :delivery_frequency, in: %w(single weekly fortnightly monthly)

      DATA_FIELDS =  [:box_type, :dislikes, :likes, :delivery_frequency, :delivery_days,
        :next_delivery_date]
      attr_accessor *DATA_FIELDS

      def add_delivery_day(day)
        self.delivery_days ||= []
        self.delivery_days << day
      end

      def delivery_days
        (@delivery_days.present? && @delivery_days || '')
      end
    end

    def self.log(text)
      puts text if @@verbosity != :none
    end
  end
end
