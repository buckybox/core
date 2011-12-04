module DistributorsHelper
  def distributor_address(distributor, options = {})
    i = distributor.invoice_information
    join_with = (options[:single_line] ? ', ' : '<br/>')

    address = [i.billing_address_1]
    address << i.billing_address_2 if i.billing_address_2.blank?
    address += [i.billing_suburb, "#{i.billing_city}, #{i.billing_postcode}"]
    address << i.phone if options[:with_phone]

    return address.join(join_with).html_safe
  end
end
