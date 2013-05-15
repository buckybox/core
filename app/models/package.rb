class Package < ActiveRecord::Base
  belongs_to :order
  belongs_to :packing_list
  belongs_to :original_package, class_name: 'Package', foreign_key: 'original_package_id'

  has_one :new_package, class_name: 'Package', foreign_key: 'original_package_id'
  has_one :distributor, through: :packing_list
  has_one :box,         through: :order
  has_one :route,       through: :order
  has_one :account,     through: :order
  has_one :customer,    through: :order
  has_one :address,     through: :order

  has_many :deliveries

  monetize :archived_box_price_cents
  monetize :archived_route_fee_cents
  monetize :archived_consumer_delivery_fee_cents

  acts_as_list scope: :packing_list_id

  attr_accessible :order, :order_id, :packing_list, :status, :position

  STATUS = %w(unpacked packed) #TODO: change to state_mchine next time this is touched
  PACKING_METHOD = %w(manual auto)

  validates_presence_of :order, :packing_list_id, :status
  validates_inclusion_of :status, in: STATUS, message: "%{value} is not a valid status"
  validates_inclusion_of :packing_method, in: PACKING_METHOD, message: "%{value} is not a valid packing method", if: 'status == "packed"'

  before_validation :default_status, if: 'status.nil?'
  before_validation :default_packing_method, if: 'status == "packed" && packing_method.nil?'

  before_save :archive_data
  after_save :save_one_off_extra_order

  scope :originals, where(original_package_id: nil)

  scope :unpacked, where(status: 'unpacked')
  scope :packed, where(status: 'packed')

  serialize :archived_extras
  serialize :archived_address_details, Address

  default_value_for :status, 'unpacked'
  default_value_for :packing_method, 'auto'
  default_value_for :archived_consumer_delivery_fee_cents, 0

  delegate :date, to: :packing_list, allow_nil: true

  def self.calculated_individual_price(box_price, route_fee, customer_discount = nil)
    box_price = box_price.price if box_price.is_a?(Box)
    route_fee = route_fee.fee   if route_fee.is_a?(Route)
    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)

    total_price = box_price + route_fee

    customer_discount ? discounted(total_price, customer_discount) : total_price
  end

  def self.calculated_extras_price(order_extras, customer_discount = nil)
    order_extras = order_extras.map(&:to_hash) unless order_extras.is_a?(Hash)
    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)

    total_price = order_extras.map do |order_extra|
      money = Money.new(order_extra[:price_cents], order_extra[:currency])
      count = (order_extra[:count].to_i || 0)
      money * count
    end.sum

    customer_discount ? discounted(total_price, customer_discount) : total_price
  end

  def self.discounted(price, customer_discount = nil)
    return price if customer_discount.nil? # Convenience so we don't have to check all over app for nil

    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)

    price * (1 - customer_discount)
  end

  def price
    result = individual_price
    result = result * archived_order_quantity if archived_order_quantity
    result += individual_extras_price if archived_extras.present?

    return result
  rescue
    raise "Error calculating price: #{individual_price.inspect} * #{archived_order_quantity.inspect}"
  end

  def total_price
    if archived_consumer_delivery_fee_cents > 0
      price + archived_consumer_delivery_fee
    else
      price
    end
  end

  def quantity
    archived_order_quantity
  end

  def individual_price
    Package.calculated_individual_price(archived_box_price, archived_route_fee, archived_customer_discount)
  end

  def individual_extras_price
    Package.calculated_extras_price(archived_extras, archived_customer_discount)
  end

  def string_pluralize
    quantity = archived_order_quantity
    box_name = archived_box_name
    "#{quantity || 0} " + ((quantity == 1 || quantity =~ /^1(\.0+)?$/) ? box_name : box_name.pluralize)
  end

  def extras_description
    Package.extras_description(archived_extras)
  end

  def extras_summary
    Package.extras_summary(archived_extras)
  end

  def self.extras_summary(archived_extras)
    archived_extras.is_a?(Hash) ? archived_extras : archived_extras.map(&:to_hash)
  end

  def self.contents_description(box_name, order_extras)
    box_name = box_name.name if box_name.is_a? Box

    result = "#{box_name}"
    result << ", #{extras_description(order_extras)}" if order_extras.present?

    return result
  end

  def contents_description
    Package.contents_description(archived_box_name, archived_extras)
  end

  def self.extras_description(order_extras)
    order_extras = order_extras.map(&:to_hash) unless order_extras.is_a? Hash
    order_extras.map{ |e| "#{e[:count]}x #{e[:name]} #{e[:unit]}" }.join(', ')
  end

  def archived_extras
    self[:archived_extras] || []
  end

  # TODO: Not sure if this fits in the model might need to go in Delivery CSV model down the road
  def self.csv_headers
    [
      'Delivery Route', 'Delivery Sequence Number', 'Delivery Pickup Point Name',
      'Order Number', 'Package Number', 'Delivery Date', 'Customer Number', 'Customer First Name',
      'Customer Last Name', 'Customer Phone', 'New Customer', 'Delivery Address Line 1', 'Delivery Address Line 2',
      'Delivery Address Suburb', 'Delivery Address City', 'Delivery Address Postcode', 'Delivery Note',
      'Box Contents Short Description', 'Box Type', 'Box Likes', 'Box Dislikes', 'Box Extra Line Items',
      'Price', 'Bucky Box Transaction Fee', 'Total Price', 'Customer Email', 'Customer Special Preferences'
    ]
  end

  def to_csv
    # At the moment a package only has one delivery. This will change with recheduling, repacking and the 
    # refactor. Was included because we thought we were going to do rescheduling sooner then we did.
    delivery = deliveries.ordered.first
    [
      route.name,
      ((!delivery.nil? && delivery.delivery_number) ? ("%03d" % delivery.delivery_number) : nil),
      nil,
      order.id,
      id,
      date.strftime("%-d %b %Y"),
      customer.number,
      customer.first_name,
      customer.last_name,
      address.phones.default_number,
      (customer.new? ? 'NEW' : nil),
      archived_address_details.address_1,
      archived_address_details.address_2,
      archived_address_details.suburb,
      archived_address_details.city,
      archived_address_details.postcode,
      archived_address_details.delivery_note,
      string_sort_code,
      archived_box_name,
      archived_substitutions,
      archived_exclusions,
      extras_description,
      price,
      archived_consumer_delivery_fee,
      total_price,
      customer.email,
      customer.special_order_preference
    ]
  end

  def archived_substitutions
    read_attribute(:archived_substitutions) || order.substitutions.map(&:name).join(', ')
  end

  def archived_exclusions
    read_attribute(:archived_exclusions) || order.exclusions.map(&:name).join(', ')
  end

  def archived_address
    if has_archived_address_details?
      read_attribute(:archived_address)
    else
      archived_address_details.join(', ')
    end
  end

  def address_hash
    if has_archived_address_details?
      archived_address
    else
      archived_address_details.address_hash
    end
  end

  def has_archived_address_details?
    !archived_address_details.id.nil?
  end
  
  def string_sort_code
    result = archived_box_name || ''
    result += '+L' unless archived_exclusions.blank?
    result += '+D' unless archived_substitutions.blank?

    return result.upcase
  end

  def set_one_off_extra_order(order)
    @one_off_extra_order = order
  end

  private

  def delivery
    deliveries.order("created_at DESC").first
  end

  def archive_data
    if status != 'packed'
      self.archived_address               = address.join(', ')
      self.archived_address_details       = address

      self.archived_box_name              = box.name
      self.archived_customer_name         = customer.name

      self.archived_box_price             = box.price
      self.archived_route_fee             = route.fee
      self.archived_customer_discount     = customer.discount
      self.archived_order_quantity        = order.quantity

      self.archived_substitutions         = order.substitutions.map(&:name).join(', ')
      self.archived_exclusions            = order.exclusions.map(&:name).join(', ')
      # The association chain to get a distributor was causing a callback loop so have to do this instead.
      found_distributor = Distributor.find_by_id(packing_list.distributor_id) if packing_list

      if found_distributor && found_distributor.separate_bucky_fee?
        self.archived_consumer_delivery_fee = found_distributor.consumer_delivery_fee
      end

      return archive_extras
    end
  end

  def archive_extras
    if archived_extras.blank?
      self.archived_extras = order.pack_and_update_extras(self)
    end
  end

  def save_one_off_extra_order
    @one_off_extra_order.set_extras_package!(self) if @one_off_extra_order.present?
  end
end
