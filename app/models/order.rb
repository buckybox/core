class Order < ActiveRecord::Base
  belongs_to :account
  has_one :customer, :through => :account

  belongs_to :box
  has_one :distributor, :through => :box

  has_many :deliveries
  
  acts_as_taggable

  attr_accessible :box, :box_id, :account, :account_id, :quantity, :likes, :dislikes, :completed, :frequency

  FREQUENCIES = %w(single weekly fortnightly)

  validates_presence_of :box, :quantity, :frequency
  validates_presence_of :account, :on => :update
  validates_numericality_of :quantity, :greater_than => 0
  validates_inclusion_of :frequency, :in => FREQUENCIES, :message => "%{value} is not a valid frequency"
  validate :box_distributor_equals_customer_distributor

  before_save :setup_deliveries, :if => :just_completed?

  scope :completed, where(:completed => true)

  def price
    box.price #will likely need to copy this to the order model at some stage
  end

  def customer= cust
    self.account = cust.account
  end

  def just_completed?
    completed_changed? && completed?
  end

  def is_preorder?
    false #false because we don't do preoders yet
  end

  def change_account_balance
    if completed_changed?
      amount = box.price * quantity
      account.subtract_from_balance(amount, :kind => 'order', :description => "[ID##{id}] Placed an order for #{string_pluralize} at #{box.price} each.")
      account.save
    elsif completed? && quantity_changed?
      old_quantity, new_quantity = quantity_change
      amount = box.price * (old_quantity - new_quantity)
      account.add_to_balance(amount, :kind => 'order', :description => "[ID##{id}] Changed quantity of an order form #{old_quantity} to #{new_quantity}.")
      account.save
    end
  end

  def string_pluralize
    "#{quantity || 0} " + ((quantity == 1 || quantity =~ /^1(\.0+)?$/) ? box.name : box.name.pluralize)
  end

  protected

  def setup_deliveries
    route = Route.best_route(distributor)
   
    if route
      # create first delivery
      first_delivery =  self.deliveries.build(:route => route, :date => route.next_run)
      
      # TODO: if more than one schedule the next four
    end
  end

  def box_distributor_equals_customer_distributor
    if customer && customer.distributor_id != box.distributor_id
      errors[:box_id] = "distributor does not match customer distributor"
      return false
    end
  end
end
