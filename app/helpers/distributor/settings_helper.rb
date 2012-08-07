module Distributor::SettingsHelper
  def show_settings_metric(key, value)
    render partial: 'distributor/settings/reporting_item', locals: { key: key, value: value }
  end

  def days_in_advance(n = 7)
    # Makes [['1 day', 1],['2 days', 2],['3 days', 3],...]
    (1..n.to_i).to_a.map { |i| [pluralize(i, 'day'), i] }
  end

  def line_item_total(line_item)
    label_text = "this will affect "
    count = line_item.exclusions_count_by_customer + line_item.substitution_count_by_customer
    label_text += pluralize(count, 'customer')

    content_tag(:div, label_text, class: 'block warning') if count > 0
  end

  def line_item_use(line_item)
    exclusion_count    = line_item.exclusions_count_by_customer
    substitution_count = line_item.substitution_count_by_customer

    has_exclusions = (exclusion_count > 0)
    has_substitutions = (substitution_count > 0)

    content = image_tag('icon-customer.png', class: 'float-left') if has_exclusions || has_substitutions
    content += content_tag(:div, "-#{exclusion_count}", title: "exclude for #{pluralize(exclusion_count, 'customer')}", class: 'float-left') if has_exclusions
    content += content_tag(:div, "+#{substitution_count}", title: "substitute for #{pluralize(substitution_count, 'customer')}", class: 'float-left') if has_substitutions

    content_tag(:div, content.html_safe, class: 'block count float-right') if content
  end
end
