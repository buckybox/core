class Order < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :box
  belongs_to :customer
  belongs_to :account

  has_many :deliveries

  acts_as_taggable

  attr_accessible :distributor, :distributor_id, :box, :box_id, :customer, :customer_id, :quantity, :likes, :dislikes, :completed, :frequency

  FREQUENCIES = %w(single weekly fortnightly)

  validates_presence_of :distributor, :box, :quantity, :frequency
  validates_presence_of :customer, :on => :update
  validates_numericality_of :quantity, :greater_than => 0
  validates_inclusion_of :frequency, :in => FREQUENCIES, :message => "%{value} is not a valid frequency"

  before_save :setup_deliveries, :if => :just_completed?

  scope :completed, where(:completed => true)

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
end
