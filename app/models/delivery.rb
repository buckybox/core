class Delivery < ActiveRecord::Base
  belongs_to :order
  belongs_to :route

  has_one :box, :through => :order
  has_one :account, :through => :order
  has_one :customer, :through => :order

  attr_accessible :order, :route, :date, :status

  STATUS = %w(pending missed delivered cancelled )

  validates_presence_of :order, :date, :route, :status
  validates_inclusion_of :status, :in => STATUS, :message => "%{value} is not a valid status"
  validates_uniqueness_of :date, :scope => :order_id, :message => 'this order already has an delivery on this date'

  before_validation :default_status, :if => 'status.nil?'

  scope :pending,   where(:status => 'pending')
  scope :missed,    where(:status => 'missed')
  scope :delivered, where(:status => 'delivered')
  scope :canceled,  where(:status => 'cancelled')

  default_scope order(:date)

  belongs_to :order

  def self.within_date_range from, to
  end

  protected

  def default_status
    self.status = STATUS.first
  end
end
