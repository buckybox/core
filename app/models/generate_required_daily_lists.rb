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
  end

  def generate
    start_date = window_start_from
    end_date   = window_end_at

    newest_list_date = packing_lists.last.date if packing_lists.last

    successful = true # assume all is good with the world

    if newest_list_date && (newest_list_date > end_date)
      # Only need to delete the difference
      start_date = end_date + 1.day
      end_date = newest_list_date

      (start_date..end_date).each do |date|
        # Seek and destroy (http://youtu.be/wLBpLz5ELPI?t=3m10s) the lists that are now out of range
        packing_list = packing_lists.find_by_date(date)
        successful &= packing_list.destroy unless packing_list.nil?

        delivery_list = delivery_lists.find_by_date(date)
        successful &= delivery_list.destroy unless delivery_list.nil?
      end
    else
      # Only generate the lists that don't exist yet
      start_date = newest_list_date unless newest_list_date.nil?

      unless start_date == end_date # the packing list already exists so don't boher generating
        (start_date..end_date).each do |date|
          packing_list  = PackingList.generate_list(distributor, date)
          delivery_list = DeliveryList.generate_list(distributor, date)

          successful &= packing_list.date == date && delivery_list.date == date
        end
      end
    end

    return successful
  end
end
