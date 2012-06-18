class StockItem < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :distributor, :name

  validates_presence_of :distributor, :name
  validates_length_of :name, minimum: 1
  validates_uniqueness_of :name, scope: :distributor_id

  before_validation :cleanup_name

  def self.from_list!(distributor, text)
    raise 'You can not create stock items with blank text' if text.blank?

    distributor.stock_items.each { |si| si.destroy }

    text.split(/\r\n?/).inject([]) do |result, name|
      result << distributor.stock_items.find_or_create_by_name(name)
      result
    end
  end

  def self.to_list(distributor)
    distributor.stock_items.order(:name).map(&:name).join("\n")
  end

  private

  def cleanup_name
    self.name.downcase!
  end
end
