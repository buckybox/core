class FuturePackingList
  attr_reader :date
  attr_reader :packages
  attr_reader :all_finished

  def initialize(date, packages, all_finished)
    @date         = date
    @packages     = packages
    @all_finished = false
  end

  def ordered_packages(ids = nil)
    list_items = packages
    list_items = list_items.select { |item| ids.include?(item.id) } if ids
    list_items
  end
end
