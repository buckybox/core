module Distributor::BaseHelper
  def distributor_address(distributor, options = {})
    i = distributor.invoice_information
    join_with = (options[:single_line] ? ', ' : '<br/>')

    address = [i.billing_address_1]
    address << i.billing_address_2 if i.billing_address_2.blank?
    address += [i.billing_suburb, "#{i.billing_city}, #{i.billing_postcode}"]
    address << i.phone_1 if options[:with_phone]

    return address.join(join_with).html_safe
  end

  def topic_tab(text, path, options = {})
    css_class = (current_page?(path) ? 'active main' : 'main')
    is_image = options.delete(:image_link)

    content_tag :li do
      if is_image
        link_to image_tag(text), path, options.merge(:class => css_class)
      else
        link_to text, path, options.merge(:class => css_class)
      end
    end
  end

  def sub_tab(text, path)
    content_tag(:dd, class: current_page?(path) ? 'active' : '')  do
      link_to text, path
    end
  end
end
