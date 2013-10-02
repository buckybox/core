require "draper"

class BoxDecorator < Draper::Decorator
  include ActionView::Helpers::TextHelper # to get `pluralize` helper

  delegate_all

  def formatted_price
    object.price.zero? ? "Free" : object.price
  end

  def extras
    if object.extras_unlimited?
      "Any amount of extra items"
    else
      "Up to #{pluralize(object.extras_limit, 'extra item')}"
    end
  end

  def exclusions
    if object.exclusions_unlimited?
      "Any amount of exclusions"
    else
      "Up to #{pluralize(object.exclusions_limit, 'exclusion')}"
    end
  end

  def substitutions
    if object.substitutions_unlimited?
      "Any amount of substitutions"
    else
      "Up to #{pluralize(object.substitutions_limit, 'substitution')}"
    end
  end
end
