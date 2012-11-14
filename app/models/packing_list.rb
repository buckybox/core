FuturePackingList = Struct.new(:date, :packages, :all_finished, :quantity)

class PackingList < ActiveRecord::Base
  belongs_to :distributor

  has_many :packages, dependent: :destroy, order: :position

  attr_accessible :distributor, :date

  validates_presence_of :distributor_id, :date
  validates_uniqueness_of :date, scope: :distributor_id

  default_scope order(:date)

  scope :packed, where(status: 'packed')

  def self.collect_lists(distributor, start_date, end_date)
    result = PackingList.includes(packages: {customer: {address: {}}}).where(date:start_date..end_date, distributor_id: distributor.id).to_a

    if end_date.future?
      future_start_date = start_date
      future_start_date = (result.last.date + 1.day) if result.last

      (future_start_date..end_date).each do |date|
        result << collect_list(distributor, date)
      end
    end

    return result
  end

  def self.collect_list(distributor, date)
    if distributor.packing_lists.where(date: date).count > 0
      distributor.packing_lists.where(date: date).includes({ packages: {}}).first
    else
      order_ids = Bucky::Sql.order_ids(distributor, date)
      orders = distributor.orders.active.where(id: order_ids).includes({ account: {customer: {address:{}, deliveries: {delivery_list: {}}}}, order_extras: {}, box: {}})

      FuturePackingList.new(date, orders, false)
    end
  end

  def self.generate_list(distributor, date)
    packing_list = PackingList.find_by_distributor_id_and_date(distributor.id, date)
    packing_list ||= PackingList.create!({distributor: distributor, date: date})

    distributor.orders.active.where(id: Bucky::Sql.order_ids(distributor, date)).each do |order|
      packing_list.packages.originals.find_or_create_by_order_id(order.id)
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
