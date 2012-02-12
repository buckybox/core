FuturePackingList = Struct.new(:date, :packages, :all_finished)

class PackingList < ActiveRecord::Base
  belongs_to :distributor

  has_many :packages, :dependent => :destroy, :order => :position

  attr_accessible :distributor, :date

  validates_presence_of :distributor, :date
  validates_uniqueness_of :date, :scope => :distributor_id

  default_scope order(:date)

  def self.collect_lists(distributor, start_date, end_date)
    result = distributor.packing_lists.where(date:start_date..end_date).to_a

    if end_date.future?
      future_start_date = start_date
      future_start_date = (result.last.date + 1.day) if result.last

      orders = distributor.orders.active

      (future_start_date..end_date).each do |date|
        date_orders = []

        orders.each { |order| date_orders << order if order.schedule.occurs_on?(date) }

        result << FuturePackingList.new(date, date_orders, false)
      end
    end

    return result
  end

  def self.generate_list(distributor, date = Date.current)
    packing_list = PackingList.find_or_create_by_distributor_id_and_date(distributor.id, date)

    distributor.orders.active.each do |order|
      if order.schedule.occurs_on?(date)
        packing_list.packages.originals.find_or_create_by_order_id(order.id)
      end
    end

    return packing_list
  end

  def mark_all_as_auto_packed
    result = true

    packages.each do |package|
      package.status = 'packed'
      package.packing_method = 'auto'
      result &= package.save
    end

    return result
  end
end
