class Address < ActiveRecord::Base
  belongs_to :customer, inverse_of: :address

  attr_accessible :customer, :address_1, :address_2, :suburb, :city, :postcode, :delivery_note
  attr_accessible(*PhoneCollection.attributes)
  attr_accessor :phone
  attr_writer :distributor

  before_validation :update_phone

  validates_presence_of :customer, unless: -> { skip_validations.include? :customer }
  validate :validate_address_and_phone

  before_save :update_address_hash

  def to_s(join_with = ', ', options = {})
    result = [address_1]
    result << address_2 unless address_2.blank?
    result << suburb unless suburb.blank?
    result << city unless city.blank?
    result << postcode unless postcode.blank?

    if options[:with_phone]
      result << phones.all.join(join_with)
    end

    result.join(join_with).html_safe
  end

  alias_method :join, :to_s

  def ==(address)
    address.is_a?(Address) && [:address_1, :address_2, :suburb, :city, :postcode].all?{ |a|
      send(a) == address.send(a)
    }
  end

  def address_hash
    self[:address_hash] || compute_address_hash
  end

  def compute_address_hash
    Digest::SHA1.hexdigest([:address_1, :address_2, :suburb, :city, :postcode].collect{|a| send(a).downcase.strip rescue ''}.join(''))
  end

  def update_address_hash
    self.address_hash = compute_address_hash
  end

  # Useful for address validation without a customer
  def distributor
    customer && customer.distributor || @distributor
  end

  def phones
    @phones ||= PhoneCollection.new self
  end

  # Without arguments, returns an array of validations to skip
  #
  # With a {Symbol}s or an {Array} of {Symbol}s, run the given block skipping
  # these validations
  #
  # @params items Array|Symbol
  #   :customer Do not validate the presence of a customer
  #   :address  Do not validate address information (street, suburb, ...)
  #   :phone    Do not validate phone numbers
  def skip_validations(*items)
    items = Array(items)
    if items.empty?
      return @skip_validations ||= []
    end

    valid_items = [:customer, :address, :phone]
    unless (items - valid_items).empty?
      raise "Only #{valid_items} are allowed"
    end

    @skip_validations = items

    yield self

  ensure
    @skip_validations = [] unless items.empty?
  end

  def update_with_notify(params, customer)
    self.attributes = params
    
    return true unless changed? #nothing to save, nothing to notify

    if save
      customer.send_address_change_notification
      return true
    else
      return false
    end
  end

private

  def validate_address_and_phone
    return unless distributor
    validate_address unless skip_validations.include? :address
    validate_phone unless skip_validations.include? :phone
  end

  def validate_phone
    if distributor.require_phone && (
        customer && customer.new_record? ||
        PhoneCollection.attributes.any? { |type| send("#{type}_changed?") }
      ) &&
      PhoneCollection.attributes.all? { |type| self[type].blank? }

      errors[:phone_number] << "can't be blank"
    end
  end

  def validate_address
    %w(address_1 address_2 suburb city postcode).each do |attr|
      if distributor.public_send("require_#{attr}") && (
          customer && customer.new_record? ||
          send("#{attr}_changed?")
        )

        validates_presence_of attr
      end
    end
  end

  # Handy helper to update a given number type (used in the webstore)
  def update_phone
    return unless phone

    type, number = phone[:type], phone[:number]
    return unless type.present?

    self.send("#{type}_phone=", number)
  end
end
