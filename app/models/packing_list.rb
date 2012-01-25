class PackingList < ActiveRecord::Base
  belongs_to :distributor

  has_many :packages, :order => :position

  attr_accessible :distributor, :date

  validates_presence_of :distributor, :date
  validates_uniqueness_of :date, :scope => :distributor_id

  default_scope order(:date)

  def self.generate_list(distributor, date = Date.today)
    packing_list = PackingList.find_or_create_by_distributor_id_and_date(distributor.id, date)

    distributor.orders.active.each do |order|
      if order.schedule.occurs_on?(date)
        package = packing_list.packages.originals.find_or_create_by_order_id(order.id)
      end
    end
  end
end
