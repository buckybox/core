require "draper"

class BoxDecorator < Draper::Decorator
  delegate_all

  def formatted_price
    object.price.zero? ? "Free" : object.price
  end

  def extras
    if object.extras_unlimited?
      "Any amount of extra items"
    else
      "Up to #{object.extras_limit} extra items"
    end
  end

  def exclusions
    if object.exclusions_unlimited?
      "Any amount of exclusions"
    else
      "Up to #{object.exclusions_limit} exclusions"
    end
  end

  def substitutions
    if object.substitutions_unlimited?
      "Any amount of substitutions"
    else
      "Up to #{object.substitutions_limit} substitutions"
    end
  end
end
