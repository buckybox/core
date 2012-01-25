class Package < ActiveRecord::Base
  belongs_to :order
  belongs_to :packing_list
  belongs_to :original_package, :class_name => 'Package', :foreign_key => 'original_package_id'

  has_one :distributor, :through => :packing_list
  has_one :new_package, :class_name => 'Package', :foreign_key => 'original_package_id'

  has_many :deliveries, :order => :date

  acts_as_list :scope => :packing_list

  attr_accessible :order, :order_id, :packing_list, :status, :position

  STATUS = %w(unpacked packed)

  validates_presence_of :packing_list, :status
  validates_inclusion_of :status, :in => STATUS, :message => "%{value} is not a valid status"

  before_validation :default_status, :if => 'status.nil?'

  scope :originals, where(original_package_id:nil)

  private

  def default_status
    self.status = 'unpacked'
  end
end
