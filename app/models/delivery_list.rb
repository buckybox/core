FutureDeliveryList = Struct.new(:date, :deliveries, :all_finished)

class DeliveryList < ActiveRecord::Base
  belongs_to :distributor

  has_many :deliveries, :order => :position, :include => [:box, :customer, :address, :route]

  attr_accessible :distributor, :date

  validates_presence_of :distributor, :date
  validates_uniqueness_of :date, :scope => :distributor_id

  default_scope order(:date)

  def self.collect_lists(distributor, start_date, end_date)
    result = distributor.delivery_lists.where(date:start_date..end_date).to_a

    if end_date.future?
      future_start_date = start_date
      future_start_date = (result.last.date + 1.day) if result.last

      orders = distributor.orders

      (future_start_date..end_date).each do |date|
        date_orders = []

        orders.each do |order|
          date_orders << order if order.schedule.occurs_on?(date)
        end

        result << FutureDeliveryList.new(date, date_orders, false)
      end
    end

    return result
  end

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

  def all_finished
    deliveries.all? { |delivery| delivery.status != 'pending' }
  end
end
