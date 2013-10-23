# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'

    inflect.singular /(ss)$/i, '\1' # for things like address and business
    inflect.irregular 'information', 'information'
end

class String
  def questionize
    "#{self.underscore}?"
  end

  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError, "invalid value for boolean: #{self.inspect}"
  end
end
