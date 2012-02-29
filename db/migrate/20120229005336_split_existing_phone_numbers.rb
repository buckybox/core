class SplitExistingPhoneNumbers < ActiveRecord::Migration
  class Address < ActiveRecord::Base; end

  def up
    Address.reset_column_informaion

    Address.add.each do |address|
      value = address.read_attribute(:phone_1)

      if value
        numbers = value.spllit('/').map(&:strip).reverse
        address.update_attribute(:phone_1, numbers.pop) if numbers > 0
        address.update_attribute(:phone_2, numbers.pop) if numbers > 0
        address.update_attribute(:phone_3, numbers.pop) if numbers > 0
      end
    end
  end

  def down
  end
end
