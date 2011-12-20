class Delivery < ActiveRecord::Base
  belongs_to :order
  belongs_to :route

  attr_accessible :order, :route, :date, :status

  STATUS = %w(pending missed delivered cancelled )

  validates_presence_of :order, :date, :route, :status
  validates_inclusion_of :status, :in => STATUS, :message => "%{value} is not a valid status"

  before_validation :default_status, :if => 'status.nil?'

  scope :pending,   where(:scope => 'pending')
  scope :missed,    where(:scope => 'missed')
  scope :delivered, where(:scope => 'delivered')
  scope :canceled,  where(:scope => 'cancelled')

  belongs_to :order

  def self.within_date_range from, to
  end

  def box
    order.box
  end

  def account
    order.account
  end

  def customer
    account.customer
  end

  protected

  def default_status
    self.status = STATUS.first
  end
end
