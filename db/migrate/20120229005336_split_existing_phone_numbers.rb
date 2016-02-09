class SplitExistingPhoneNumbers < ActiveRecord::Migration
  class Address < ActiveRecord::Base; end

  def up
    Address.reset_column_information

    Address.all.each do |address|
      value = address.read_attribute(:phone_1)

      if value
        numbers = value.split('/').map(&:strip).reverse
        address.update_attribute(:phone_1, numbers.pop) if numbers.present?
        address.update_attribute(:phone_2, numbers.pop) if numbers.present?
        address.update_attribute(:phone_3, numbers.pop) if numbers.present?
      end
    end
  end

  def down
  end
end
