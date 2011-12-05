class Order < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :box
  belongs_to :customer
  belongs_to :account

  attr_accessible :distributor, :box, :box_id, :customer, :quantity, :likes, :dislikes, :completed, :frequency

  scope :completed, where(:completed => true)

  FREQUENCIES = %w(single weekly fortnightly)

  validates_presence_of :distributor, :box, :quantity, :frequency
  validates_presence_of :customer, :on => :update
  validates_numericality_of :quantity, :greater_than => 0
  validates_inclusion_of :frequency, :in => FREQUENCIES, :message => "%{value} is not a valid frequency"

  before_save :update_account, :if => 'completed_changed? || (completed? && quantity_changed?)'

  def update_account
    amount = (box.price * quantity)
    account.balance -= amount
    account.save

    description = 'Order was created.'
    Transaction.create(:account => account, :kind => 'order', :amount => amount, :description => description)
  end
end
