module CustomersHelper
  def customer_address(customer, options = {})
    a = customer.address
    join_with = (options[:single_line] ? ', ' : '<br/>')

    address = [a.address_1]
    address << a.address_2 unless a.address_2.blank?
    address += [a.suburb, "#{a.city}, #{a.postcode}"]
    address << a.phone if options[:with_phone]

    return address.join(join_with).html_safe
  end
end
