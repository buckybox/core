class ExtrasCsv
  include Singleton

  def self.generate(distributor, date)
    extras = distributor.extras.alphabetically
    instance.extract_customers(distributor, date)

    instance.generate(date, extras, instance.extras_summary(distributor, date))
  end

  def generate(date, extras, extras_summary)
    sum_totals(extras_summary)

    CSV.generate do |csv|
      headers(csv)
      extras.each do |extra|
        csv << [
          date.iso8601,
          extra.name,
          extra.unit,
          extra.price,
          extras_count(extra, extras_summary),
          extra.visible ? "yes" : "no",
          extras_customers(extra).sort_by(&:name).map(&:name).join(", "),
          extras_customers(extra).sort_by(&:name).map(&:email).join(", "),
        ]
      end
    end
  end

  def headers(csv)
    csv << [
      "delivery date",
      "extra line item name",
      "extra line item unit",
      "extra line item unit price",
      "quantity",
      "web store visibility",
      "customer names",
      "customer emails",
    ]
  end

  def extras_summary(distributor, date)
    packages(distributor, date).map(&:extras_summary).flatten
  end

  def extract_customers(distributor, date)
    @extras_customers_store = {}
    packages(distributor, date).each do |package|
      package.extras_summary.each do |extra_summary|
        @extras_customers_store[name_with_unit(extra_summary)] ||= []
        @extras_customers_store[name_with_unit(extra_summary)] |= [package.customer]
      end
    end
  end

private

  def extras_count(extra, extras_summary)
    @extras_count_store[name_with_unit(extra)] || 0
  end

  def extras_customers(extra)
    @extras_customers_store[name_with_unit(extra)] || []
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
