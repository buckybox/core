require 'draper'

class ExtraDecorator < Draper::Decorator
  delegate_all

  def formatted_price
    object.price.zero? ? "Free" : object.price
  end

  def visible
    !object.hidden
  end

  def with_units
    "#{object.name} (#{object.unit})"
  end

  # FIXME
  def extra_image
    OpenStruct.new({ tiny_thumb: OpenStruct.new({ url: nil }) })
  end
end
