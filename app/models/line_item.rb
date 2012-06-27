class LineItem < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :distributor, :name

  validates_presence_of :distributor, :name
  validates_length_of :name, minimum: 1
  validates_uniqueness_of :name, scope: :distributor_id

  before_validation :cleanup_name

  default_scope order(:name)

  def self.from_list!(distributor, text)
    return false if text.blank?

    distributor.line_items.each { |si| si.destroy }

    text.split(/\r\n?|\r?\n/).inject([]) do |result, name|
      result << distributor.line_items.find_or_create_by_name(name)
      result
    end
  end

  def self.to_list(distributor)
    distributor.line_items.order(:name).map(&:name).join("\n")
  end

  private

  def cleanup_name
    self.name = self.name.titleize
  end
end
