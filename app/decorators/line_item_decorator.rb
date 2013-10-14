require "draper"

class LineItemDecorator < Draper::Decorator
  include ActionView::Helpers::TagHelper  # content_tag
  include ActionView::Helpers::TextHelper # pluralize

  delegate_all

  def using_customers
    exclusion_count    = object.exclusions_count_by_customer
    substitution_count = object.substitution_count_by_customer

    has_exclusions = (exclusion_count > 0)
    has_substitutions = (substitution_count > 0)

    if has_exclusions || has_substitutions
      content = [content_tag(:i, nil, class: 'icon-user icon-white')]
      title = []

      if has_exclusions
        content << content_tag(:span, "-#{exclusion_count}")
        title << "exclude for #{pluralize(exclusion_count, 'customer')}"
      end

      if has_substitutions
        content << content_tag(:span, "+#{substitution_count}")
        title << "substitute for #{pluralize(substitution_count, 'customer')}"
      end

      content = content.join(' ')
      title = title.join(' and ')
      content_tag(:span, content.html_safe, title: title, class: 'badge badge-info')
    end
  end

  def affected_customers
    label_text = "This will affect "
    count = object.exclusions_count_by_customer + object.substitution_count_by_customer
    label_text += pluralize(count, 'customer')

    content_tag(:span, label_text, class: 'label label-warning warning') if count > 0
  end
end

