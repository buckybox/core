class Delivery < ActiveRecord::Base
  belongs_to :order
  belongs_to :delivery_list
  belongs_to :route
  belongs_to :package

  has_one :distributor, :through => :delivery_list
  has_one :box, :through => :order
  has_one :account, :through => :order
  has_one :customer, :through => :order
  has_one :address, :through => :order

  acts_as_list :scope => [:delivery_list_id, :route_id]

  attr_accessible :order, :order_id, :route, :status, :delivery_method, :delivery_list, :package, :package_id

  STATUS = %w(pending delivered cancelled rescheduled repacked)
  DELIVERY_METHOD = %w(manual auto)

  validates_presence_of :order, :route, :status, :delivery_list, :package
  validates_inclusion_of :status, :in => STATUS, :message => "%{value} is not a valid status"
  validates_inclusion_of :delivery_method, :in => DELIVERY_METHOD, :message => "%{value} is not a valid delivery method", :if => 'status == "delivered"'

  before_validation :default_route, :if => 'route.nil?'
  before_validation :default_status, :if => 'status.nil?'
  before_validation :default_delivery_method, :if => 'status == "delivered" && delivery_method.nil?'
  before_validation :changed_status, :if => 'status_changed?'

  before_create :add_delivery_number

  scope :pending,     where(status:'pending')
  scope :delivered,   where(status:'delivered')
  scope :cancelled,   where(status:'cancelled')
  scope :rescheduled, where(status:'rescheduled')
  scope :repacked,    where(status:'repacked')

  def self.change_statuses(deliveries, new_status, options = {})
    return false unless STATUS.include?(new_status)
    return false if (new_status == 'rescheduled' || new_status == 'repacked') && options[:date].nil?

    result = true

    deliveries.each do |delivery|
      delivery.status = new_status
      result &= delivery.save!
    end

    return result
  end

  def date
    delivery_list.date
  end

  def future_status?
    status == 'pending'
  end

  protected

  def default_route
    self.route = order.route
  end

  def default_status
    self.status = 'pending'
  end

  def default_delivery_method
    self.delivery_method = 'manual'
  end

  def add_delivery_number
    self.delivery_number = self.position
  end

  def changed_status
    old_status, new_status = self.status_change

    subtract_from_account if new_status == 'delivered'
    add_to_account        if old_status == 'delivered'

    # Commenting out for now as not doing reschedule repack just yet
    #remove_from_schedule  if old_status == 'rescheduled' || old_status == 'repacked'
    #add_to_schedule       if new_status == 'rescheduled' || new_status == 'repacked'
  end

  def subtract_from_account
    account.subtract_from_balance(
      package.archived_box_price * package.archived_order_quantity,
      :kind => 'delivery',
      :description => "[ID##{id}] Delivery was made of #{package.string_pluralize} at #{package.archived_box_price} each."
    )
    errors.add(:base, 'Problem subtracting balance from account on delivery status change.') unless account.save
  end

  def add_to_account
    account.add_to_balance(
      package.archived_box_price * package.archived_order_quantity,
      :kind => 'delivery',
      :description => "[ID##{id}] Delivery reversal. #{package.string_pluralize} at #{package.archived_box_price} each."
    )
    errors.add(:base, 'Problem adding balance from account on delivery status change.') unless account.save
  end

  def remove_from_schedule
    #order.remove_scheduled_delivery(new_delivery) if new_delivery

    unless new_delivery
      errors.add(:base, 'There is no "new delivery" to remove from the schedule so this status change can not be completed.')
    end

    unless new_delivery && new_delivery.destroy
      errors.add(:base, 'The delivery could not be destroyed.')
    end

    unless order.save
      errors.add(:base, 'The order could not be saved.')
    end
  end

  def add_to_schedule
    #order.add_scheduled_delivery(new_delivery) if new_delivery

    unless new_delivery
      errors.add(:base, 'There is no "new delivery" to add to the schedule so this status change can not be completed.')
    end

    unless order.save
      errors.add(:base, 'The order could not be saved.')
    end
  end
end
