class LineItem < ActiveRecord::Base
  belongs_to :distributor

  has_many :exclusions,    dependent: :destroy
  has_many :substitutions, dependent: :destroy

  attr_accessible :distributor, :name

  validates_presence_of :distributor, :name
  validates_length_of :name, minimum: 1
  validates_uniqueness_of :name, scope: :distributor_id

  before_validation :cleanup_name

  default_scope order(:name)

  def self.from_list(distributor, text)
    return false if text.blank?

    text.split(/\r\n?|\r?\n|\s*,\s*/).inject([]) do |result, name|
      result << distributor.line_items.find_or_create_by_name(name)
      result
    end

    return all.blank? ? nil : all
  end

  def self.bulk_update(distributor, line_item_hash)
    line_item_hash ||= {}

    line_item_hash.each do |id, name|
      line_item = LineItem.find(id)
      name = name.titleize

      if name.blank?
        line_item.destroy
      elsif name != line_item.name
        new_line_item = LineItem.find_or_create_by_name(name, distributor: distributor)
        move_exclustions_and_substitutions!(line_item, new_line_item)
      end
    end
  end

  def self.move_exclustions_and_substitutions!(old_line_item, new_line_item)
    Exclusion.change_line_items!(old_line_item, new_line_item)
    Substitution.change_line_items!(old_line_item, new_line_item)
    old_line_item.delete
  end

  def exclusions_count_by_customer
    exclusions.active.uniq_by{ |e| e.customer.id }.size
  end

  def substitution_count_by_customer
    substitutions.active.uniq_by{ |e| e.customer.id }.size
  end

  private

  def cleanup_name
    self.name = self.name.titleize
  end
end
