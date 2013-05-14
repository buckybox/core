class Address < ActiveRecord::Base
  belongs_to :customer, inverse_of: :address

  attr_accessible :customer, :address_1, :address_2, :suburb, :city, :postcode, :delivery_note, :phone_1, :phone_2, :phone_3
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
      result << "Phone 1: #{phone_1}" unless phone_1.blank?
      result << "Phone 2: #{phone_2}" unless phone_2.blank?
      result << "Phone 3: #{phone_3}" unless phone_3.blank?
    end

    return result.join(join_with).html_safe
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

private

  def phone
    phone_1
  end

  def validate_address
    %w(address_1 address_2 suburb city post_code phone).each do |attr|
      require_method = "require_#{attr}"

      validates_presence_of attr if distributor.send(require_method)
    end
  end
end
