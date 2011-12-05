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

  def topic_tab(text, path, options = {})
    css_class = (current_page?(path) ? 'active' : '')

    content_tag :dd do
      if options[:image_link]
        link_to image_tag(text), path, :class => css_class
      else
        link_to text, path, :class => css_class
      end
    end
  end
end
