require 'draper'
require_relative 'extras_decorator'

class ExtraDecorator < Draper::Decorator
  delegate_all

  def with_units
    "#{object.name} (#{object.unit})"
  end
end
