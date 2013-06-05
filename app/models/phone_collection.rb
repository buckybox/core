# Class to store multiple phone numbers
# Each number is associated with a type (mobile, home, work)
class PhoneCollection
  TYPES = %w(mobile home work).inject({}) do |hash, type|
    hash.merge!(type => "#{type}_phone")
  end.freeze

  def self.attributes
    TYPES.values
  end

  def initialize address
    @address = address
  end

  def all
    TYPES.each_value.map do |attribute|
      phone = @address.send(attribute)
      "#{attribute.humanize}: #{phone}" unless phone.blank?
    end.compact
  end

  def default_number
    @address.reload.send(default[:attribute])
  end

  def default_type
    default[:type]
  end

private

  # Default number attributes
  def default
    default = TYPES.first
    { type: default.first, attribute: default.last }
  end
end

