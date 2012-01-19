class Delivery < ActiveRecord::Base
  belongs_to :order
  belongs_to :route
  belongs_to :old_delivery, :class_name => 'Delivery', :foreign_key => 'old_delivery_id'

  has_one :new_delivery, :class_name => 'Delivery', :foreign_key => 'old_delivery_id'
  has_one :box, :through => :order
  has_one :account, :through => :order
  has_one :customer, :through => :order
  has_one :address, :through => :order
  has_one :distributor, :through => :order

  composed_of :price,
    :class_name => "Money",
    :mapping => [%w(archived_price_cents cents), %w(archived_currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :order, :route, :date, :status, :old_delivery

  STATUS = %w(pending delivered cancelled rescheduled repacked)
  PACKING_STATUS = %w(packed unpacked)
  DELIVERY_METHOD = %w(manual auto)

  validates_presence_of :order, :date, :route, :status
  validates_inclusion_of :status, :in => STATUS, :message => "%{value} is not a valid status"
  validates_inclusion_of :packing_status, :in => PACKING_STATUS, :message => "%{value} is not a valid packing status"
  validate :status_for_date, :unless => :future_status?

  before_validation :default_status, :if => 'status.nil?'
  before_validation :default_packing_status, :if => 'packing_status.nil?'
  before_validation :changed_status, :if => 'status_changed?'
  before_save :archive_data

  scope :pending,     where(:status => 'pending')
  scope :delivered,   where(:status => 'delivered')
  scope :cancelled,   where(:status => 'cancelled')
  scope :rescheduled, where(:status => 'rescheduled')
  scope :repacked,    where(:status => 'repacked')

  default_scope order(:date)

  def self.change_statuses(deliveries, new_status, options = {})
    return false unless STATUS.include?(new_status)
    return false if (new_status == 'rescheduled' || new_status == 'repacked') && options[:date].nil?

    new_date = Date.parse(options[:date]) if options[:date]
    result = true

    if new_status == 'rescheduled' || new_status == 'repacked'
      ActiveRecord::Base.transaction do
        deliveries.each do |d|
          new_delivery = Delivery.new(order: d.order, route: d.route, status: 'pending', date: new_date, old_delivery: d)
          result &= new_delivery.save!
        end
      end
    end

    if result
      deliveries.each do |delivery|
        delivery.status = new_status
        result &= delivery.save!
      end
    end

    return result
  end

  def future_status?
    status == 'pending'
  end

  protected

  def status_for_date
    errors.add(:status, "of #{status} can not be set for a future date") if date > Date.today
  end

  def default_status
    self.status = 'delivered'
  end

  def default_packing_status
    self.packing_status = 'unpacked'
  end

  def changed_status
    old_status, new_status = self.status_change

    subtract_from_account if new_status == 'delivered'
    add_to_account        if old_status == 'delivered'

    remove_from_schedule  if old_status == 'rescheduled' || old_status == 'repacked'
    add_to_schedule       if new_status == 'rescheduled' || new_status == 'repacked'

    #TODO: Need to add this when the packing screen is sorted
    #update_packing(old_status, new_status)
  end

  def subtract_from_account
    account.subtract_from_balance(
      box.price * order.quantity,
      :kind => 'delivery',
      :description => "[ID##{id}] Delivery was made of #{order.string_pluralize} at #{box.price} each."
    )
    errors.add(:base, 'Problem subtracting balance from account on delivery status change.') unless account.save
  end

  def add_to_account
    account.add_to_balance(
      box.price * order.quantity,
      :kind => 'delivery',
      :description => "[ID##{id}] Delivery reversal. #{order.string_pluralize} at #{box.price} each."
    )
    errors.add(:base, 'Problem adding balance from account on delivery status change.') unless account.save
  end

  def remove_from_schedule
    order.remove_scheduled_delivery(new_delivery) if new_delivery

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
    order.add_scheduled_delivery(new_delivery) if new_delivery

    unless new_delivery
      errors.add(:base, 'There is no "new delivery" to add to the schedule so this status change can not be completed.')
    end

    unless order.save
      errors.add(:base, 'The order could not be saved.')
    end
  end
end
