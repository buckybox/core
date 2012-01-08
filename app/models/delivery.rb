class Delivery < ActiveRecord::Base
  belongs_to :order
  belongs_to :route
  belongs_to :old_delivery, :class_name => 'Delivery', :foreign_key => 'old_delivery_id'

  has_one :new_delivery, :class_name => 'Delivery'
  has_one :box, :through => :order
  has_one :account, :through => :order
  has_one :customer, :through => :order

  attr_accessible :order, :route, :date, :status, :old_delivery, :new_delivery

  STATUS = %w(pending delivered cancelled rescheduled repacked)

  validates_presence_of :order, :date, :route, :status
  validates_inclusion_of :status, :in => STATUS, :message => "%{value} is not a valid status"
  validates_uniqueness_of :date, :scope => :order_id, :message => 'this order already has an delivery on this date'
  validate :status_for_date, :unless => "status == 'pending'"

  before_validation :default_status, :if => 'status.nil?'
  before_save :changed_status, :if => 'status_changed?'

  scope :pending,   where(:status => 'pending')
  scope :delivered, where(:status => 'delivered')
  scope :cancelled, where(:status => 'cancelled')

  default_scope order(:date)

  def self.change_statuses(deliveries, status, options = {})
    return false if STATUS.include?(status)

    date = Date.parse(options[:date]) if options[:date]
    result = true

    deliveries.each do |delivery| 
      delivery.status = status
      result &&= delivery.save
    end

    return result
  end

  protected

  def status_for_date
    if date > Date.today
      errors.add(:status, "of #{status} can not be set for a future date")
    end
  end

  def default_status
    self.status = STATUS.first
  end

  def changed_status
    old_status, new_status = self.status_change

    if old_status == 'pending' && new_status == 'delivered'
      account.subtract_from_balance(
        box.price * order.quantity,
        :kind => 'delivery',
        :description => "[ID##{id}] Delivery was made of #{order.string_pluralize} at #{box.price} each."
      )
      account.save
    elsif old_status == 'delivered' && new_status == 'pending'
      account.add_to_balance(
        box.price * order.quantity,
        :kind => 'delivery',
        :description => "[ID##{id}] Reverted a delivery back to pending. #{order.string_pluralize} at #{box.price} each."
      )
      account.save
    end
  end
end
