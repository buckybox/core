class Delivery < ActiveRecord::Base
  belongs_to :order
  belongs_to :route

  has_one :box, :through => :order
  has_one :account, :through => :order
  has_one :customer, :through => :order

  attr_accessible :order, :route, :date, :status

  STATUS = %w(pending delivered cancelled)

  validates_presence_of :order, :date, :route, :status
  validates_inclusion_of :status, :in => STATUS, :message => "%{value} is not a valid status"
  validates_uniqueness_of :date, :scope => :order_id, :message => 'this order already has an delivery on this date'
  validate :status_for_date, :unless => "status == 'pending'"

  before_validation :default_status, :if => 'status.nil?'

  scope :pending,   where(:status => 'pending')
  scope :delivered, where(:status => 'delivered')
  scope :cancelled, where(:status => 'cancelled')
  scope :missed,    where(:status => 'missed')

  default_scope order(:date)

  belongs_to :order

  protected

  def status_for_date
    if date > Date.today
      errors.add(:status, "of #{status} can not be set for a future date")
    end
  end

  def default_status
    self.status = STATUS.first
  end
end
