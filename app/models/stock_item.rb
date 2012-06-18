class StockItem < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :distributor, :name

  validates_presence_of :distributor, :name

  def self.from_list!(distributor, text)
    raise 'You can not create stock items with blank text' if text.blank?

    distributor.stock_items.each { |si| si.destroy }

    text.split("\n").inject([]) do |result, name|
      result << StockItem.create(distributor: distributor, name: name)
      result
    end
  end

  def self.to_list(distributor)

  end
end
