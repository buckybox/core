module Distributor::SettingsHelper
  def show_settings_metric(key, value)
    render partial: 'distributor/settings/reporting_item', locals: { key: key, value: value }
  end

  def days_in_advance(n = 7)
    # Makes [['1 day', 1],['2 days', 2],['3 days', 3],...]
    (0..n.to_i).to_a.map { |i| [pluralize(i, 'day'), i] }
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

    label_text = ''
    label_text = "-#{exclusion_count}"    if exclusion_count > 0
    label_text = "+#{substitution_count}" if substitution_count > 0

    content_tag(:div, label_text, class: 'block count float-right') unless label_text.blank?
  end
end
