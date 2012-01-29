class Package < ActiveRecord::Base
  belongs_to :order
  belongs_to :packing_list
  belongs_to :original_package, :class_name => 'Package', :foreign_key => 'original_package_id'

  has_one :distributor, :through => :packing_list
  has_one :new_package, :class_name => 'Package', :foreign_key => 'original_package_id'
  has_one :box, :through => :order
  has_one :account, :through => :order
  has_one :customer, :through => :order
  has_one :address, :through => :order

  has_many :deliveries, :order => :date

  composed_of :archived_box_price,
    :class_name => "Money",
    :mapping => [%w(archived_price_cents cents), %w(archived_currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  acts_as_list :scope => :packing_list_id

  attr_accessible :order, :order_id, :packing_list, :status, :position

  STATUS = %w(unpacked packed)
  PACKING_METHOD = %w(manual auto)

  validates_presence_of :packing_list, :status
  validates_inclusion_of :status, :in => STATUS, :message => "%{value} is not a valid status"
  validates_inclusion_of :packing_method, :in => PACKING_METHOD, :message => "%{value} is not a valid packing method", :if => 'status == "packed"'

  before_validation :default_status, :if => 'status.nil?'
  before_validation :default_packing_method, :if => 'status == "delivered"'

  before_save :archive_data

  scope :originals, where(original_package_id:nil)

  private

  def default_status
    self.status = 'unpacked'
  end

  def default_packing_method
    self.delivery_method = 'manual'
  end

  def archive_data
    self.archived_address = address.join(', ')
    self.archived_order_quantity = order.quantity
    self.archived_box_name = box.name
    self.archived_box_price = box.price
    self.archived_customer_name = customer.name
  end
end
