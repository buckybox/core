class DeliveryList < ActiveRecord::Base
  belongs_to :distributor

  has_many :deliveries, :order => :position

  attr_accessible :distributor, :date

  validates_presence_of :distributor, :date
  validates_uniqueness_of :date, :scope => :distributor_id

  default_scope order(:date)

  def self.generate_list(distributor, date = Date.today)
    delivery_list = DeliveryList.find_or_create_by_distributor_id_and_date(distributor.id, date)
    packing_list = PackingList.find_or_create_by_distributor_id_and_date(distributor.id, date)

    packing_list.packages.each do |package|
      delivery = delivery_list.deliveries.find_or_create_by_package_id(package.id, :order => package.order)
    end
  end

  def mark_all_as_auto_delivered
    deliveries.each do |delivery|
      delivery.status = 'delivered'
      delivery.delivery_method = 'auto'
      delivery.save
    end
  end
end
