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

  acts_as_list :scope => :packing_list_id

  attr_accessible :order, :order_id, :packing_list, :status, :position

  STATUS = %w(unpacked packed)
  PACKING_METHOD = %w(manual auto)

  validates_presence_of :packing_list, :status
  validates_inclusion_of :status, :in => STATUS, :message => "%{value} is not a valid status"
  validates_inclusion_of :packing_method, :in => PACKING_METHOD, :message => "%{value} is not a valid packing method", :if => 'status == "packed"'

  before_validation :default_status, :if => 'status.nil?'
  before_validation :default_packing_method, :if => 'status == "delivered"'

  scope :originals, where(original_package_id:nil)

  private

  def default_status
    self.status = 'unpacked'
  end

  def default_packing_method
    self.delivery_method = 'manual'
  end
end
