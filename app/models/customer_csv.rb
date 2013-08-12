require 'csv'
require 'singleton'

class CustomerCSV
  include Singleton

  def self.generate(distributor, customer_ids, fields = default_fields)
    data = get_data(distributor, customer_ids)
    instance.generate(data, fields)
  end

  def generate(customers, fields = CustomerCSV.default_fields)
    @fields = fields
    CSV.generate do |csv|
      csv << headers
      customers.each { |customer| csv << generate_row(customer) }
    end
  end

private

  attr_accessor :fields

  def self.get_data(distributor, customer_ids)
    data = distributor.customers_for_export(customer_ids)
    data.decorate
  end

  def self.default_fields
    [
      :customer_number,
      :first_name,
      :last_name,
      :email,
      :last_paid_date,
      :account_balance,
      :minimum_balance,
      :halted?,
      :discount,
      :customer_labels,
      :customer_creation_date,
      :customer_creation_method,
      :sign_in_count,
      :customer_note,
      :customer_packing_notes,
      :delivery_service,
      :address_line_1,
      :address_line_2,
      :suburb,
      :city,
      :postcode,
      :delivery_note,
      :mobile_phone,
      :home_phone,
      :work_phone,
      :active_orders_count,
      :next_delivery_date,
      :next_delivery,
    ]
  end

  def headers
    fields.map { |field| field.to_s.titleize }
  end

  def generate_row(customer)
    fields.each_with_object([]) { |field, csv_row| csv_row << customer.send(field).to_s }
  end
end
