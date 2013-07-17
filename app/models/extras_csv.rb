class ExtrasCsv
  include Singleton

  def self.generate(distributor, date)
    extras = distributor.extras.alphabetically
    instance.generate(date, extras, instance.extras_summary(distributor, date))
  end

  def generate(date, extras, extras_summary)
    sum_totals(extras_summary)
    CSV.generate do |csv|
      headers(csv)
      extras.each do |extra|
        csv << [date.iso8601, extra.name, extra.unit, extra.price, extras_count(extra, extras_summary)]
      end
    end
  end

  def headers(csv)
    csv << ["delivery date", "extra line item name", "extra line item unit", "extra line item unit price", "quantity"]
  end
  
  def extras_summary(distributor, date)
    packages(distributor, date).collect(&:extras_summary).flatten
  end

  private
  def extras_count(extra, extras_summary)
    @extras_count_store[name_with_unit(extra)] || 0
  end

  def sum_totals(extras_summary)
    @extras_count_store = {}
    extras_summary.each do |extra_summary|
      @extras_count_store[name_with_unit(extra_summary)] ||= 0
      @extras_count_store[name_with_unit(extra_summary)] += extra_summary[:count]
    end
  end

  def packages(distributor, date)
    distributor.packing_list_by_date(date).ordered_packages
  end


  def name_with_unit(es)
    if es.is_a?(Hash)
      Extra.name_with_unit(es)
    else
      es.name_with_unit
    end
  end
end
