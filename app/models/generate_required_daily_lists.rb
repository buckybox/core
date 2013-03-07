class GenerateRequiredDailyLists
  attr_reader :window_start_from
  attr_reader :window_end_at
  attr_reader :packing_lists
  attr_reader :delivery_lists
  attr_reader :distributor

  def initialize(args)
    @distributor       = args[:distributor]
    @window_start_from = args[:window_start_from]
    @window_end_at     = args[:window_end_at]
    @packing_lists     = args[:packing_lists]
    @delivery_lists    = args[:delivery_lists]
    @successful        = false
  end

  def generate
    @successful = true
    (start_date..end_date).each { |date| update_lists(date) }
    @successful
  end

  def last_list
    @last_list ||= packing_lists.last
  end

  def last_list_date
    @last_list_date ||= last_list.date if last_list
  end

  def packing_list_is_longer?
    @packing_list_is_longer ||= last_list_date && (last_list_date > window_end_at)
  end

  def start_date
    @start_date ||= begin
      if packing_list_is_longer?
        window_end_at + 1.day
      else
        last_list_date ? last_list_date : window_start_from
      end
    end
  end

  def end_date
    @end_date ||= packing_list_is_longer? ? last_list_date : window_end_at
  end

  def update_lists(date)
    packing_list_is_longer? ? destroy_unneeded_lists(date) : create_needed_lists(date)
  end

  def destroy_unneeded_lists(date)
    lists_array = [packing_lists, delivery_lists]
    lists_array.each { |lists| destroy_list_by_date(lists, date) }
  end

  def destroy_list_by_date(lists, date)
    list = lists.find_by_date(date)
    @successful &= list.destroy unless list.nil?
  end

  def create_needed_lists(date)
    class_array = [PackingList, DeliveryList]
    class_array.each { |list_class| create_list_by_date(list_class, date) }
  end

  def create_list_by_date(list_class, date)
    list = list_class.generate_list(distributor, date)
    @successful &= list.date == date
  end
end
