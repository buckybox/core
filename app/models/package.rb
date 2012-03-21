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

  composed_of :archived_box_price,
    class_name: "Money",
    mapping: [%w(archived_price_cents cents), %w(archived_price_currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  composed_of :archived_route_fee,
    class_name: "Money",
    mapping: [%w(archived_fee_cents cents), %w(archived_fee_currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  acts_as_list scope: :packing_list_id

  attr_accessible :order, :order_id, :packing_list, :status, :position

  STATUS = %w(unpacked packed)
  PACKING_METHOD = %w(manual auto)

  validates_presence_of :packing_list, :status, :order
  validates_inclusion_of :status, in: STATUS, message: "%{value} is not a valid status"
  validates_inclusion_of :packing_method, in: PACKING_METHOD, message: "%{value} is not a valid packing method", if: 'status == "packed"'

  before_validation :default_status, if: 'status.nil?'
  before_validation :default_packing_method, if: 'status == "packed" && packing_method.nil?'

  before_save :archive_data

  scope :originals, where(original_package_id:nil)

  def self.calculated_price(box_price, route_fee, customer_discount)
    box_price         = box_price.price            if box_price.is_a?(Box)
    route_fee         = route_fee.fee              if route_fee.is_a?(Route)
    customer_discount = customer_discount.discount if customer_discount.is_a?(Customer)

    (box_price + route_fee) * (1 - customer_discount)
  end

  def price
    individual_price * archived_order_quantity
  end

  def quantity
    archived_order_quantity
  end

  def individual_price
    Package.calculated_price(archived_box_price, archived_route_fee, archived_customer_discount)
  end

  def string_pluralize
    quantity = archived_order_quantity
    box_name = archived_box_name
    "#{quantity || 0} " + ((quantity == 1 || quantity =~ /^1(\.0+)?$/) ? box_name : box_name.pluralize)
  end

  private

  def default_status
    self.status = 'unpacked'
  end

  def default_packing_method
    self.packing_method = 'manual'
  end

  def archive_data
    self.archived_address           = address.join(', ')

    self.archived_box_name          = box.name
    self.archived_customer_name     = customer.name

    self.archived_box_price         = box.price
    self.archived_route_fee         = route.fee
    self.archived_customer_discount = customer.discount
    self.archived_order_quantity    = order.quantity
  end
end
