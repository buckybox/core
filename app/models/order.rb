class Order < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :box
  belongs_to :customer

  attr_accessible :distributor, :box, :box_id, :customer, :quantity, :likes, :dislikes, :completed, :frequency

  FREQUENCIES = %w(single weekly fortnightly)

  validates_presence_of :distributor, :box, :quantity, :frequency
  validates_presence_of :customer, :on => :update
  validates :frequency, :inclusion => { :in => FREQUENCIES, :message => "%{value} is not a valid frequency" }
end
