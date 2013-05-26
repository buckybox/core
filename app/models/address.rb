class Address < ActiveRecord::Base
  belongs_to :customer, inverse_of: :address

  attr_accessible :customer, :address_1, :address_2, :suburb, :city, :postcode, :delivery_note
  attr_accessible(*PhoneCollection.attributes)
  attr_accessor :phone

  before_validation :update_phone

  validates_presence_of :customer
  validate :validate_address

  before_save :update_address_hash

  def join(join_with = ', ', options = {})
    result = [address_1]
    result << address_2 unless address_2.blank?
    result << suburb unless suburb.blank?
    result << city unless city.blank?

    if options[:with_postcode]
      result << postcode unless postcode.blank?
    end

    if options[:with_phone]
      result << phones.all.join(join_with)
    end

    result.join(join_with).html_safe
  end

  def ==(address)
    address.is_a?(Address) && [:address_1, :address_2, :suburb, :city].all?{ |a|
      send(a) == address.send(a)
    }
  end

  def address_hash
    self[:address_hash] || compute_address_hash
  end

  def compute_address_hash
    Digest::SHA1.hexdigest([:address_1, :address_2, :suburb, :city].collect{|a| send(a).downcase.strip rescue ''}.join(''))
  end

  def update_address_hash
    self.address_hash = compute_address_hash
  end

  # Useful for address validation without a customer
  attr_writer :distributor
  def distributor
    customer && customer.distributor || @distributor
  end

  def phones
    @phones ||= PhoneCollection.new self
  end

private

  def update_phone
    return unless phone

    type, number = phone[:type], phone[:number]
    return unless type.present?

    self.send("#{type}_phone=", number)
  end

  def validate_address
    changed_attributes = changes.keys

    if distributor.require_phone? and \
      changed_attributes.any? { |attr| attr.in? PhoneCollection.attributes } and \
      PhoneCollection.attributes.all? { |type| self[type].blank? }

      errors[:phone_number] << "can't be blank"
    end

    %w(address_1 address_2 suburb city postcode).each do |attr|
      next unless attr.in? changed_attributes

      require_method = "require_#{attr}"

      validates_presence_of attr if distributor.send(require_method)
    end
  end


    type, number = phone[:type], phone[:number]
    return unless type.present?

    self.send("#{type}_phone=", number)
  end
end
