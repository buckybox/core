require "csv"

class ExtrasCsv
  include Singleton

  def self.generate(distributor, date)
    instance.dump_current_extras(distributor)
    instance.extract_customers(distributor, date)
    extras_summary = instance.extras_summary(distributor, date)
    instance.generate(date, extras_summary)
  end

  def generate(date, extras_summary)
    sum_totals(extras_summary)

    CSV.generate do |csv|
      headers(csv)

      # use shitty data structures and this is the kind of insanity you end up with...
      extras = extras_summary.group_by { |e| e.fetch(:name) } \
        .values.map(&:first).sort_by { |e| e.fetch(:name).downcase }

      extras.each do |extra|
        name = extra.fetch(:name)
        visible = @current_extras.find_by(name: name).try(:visible)

        csv << [
          date.iso8601,
          name,
          extra.fetch(:unit),
          extra.fetch(:price),
          extras_count(extra, extras_summary),
          visible.nil? ? "N/A" : (visible ? "yes" : "no"),
          extras_customers(extra)[:names],
          extras_customers(extra)[:emails],
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
        extra_summary[:count].times do
          (@extras_customers_store[name_with_unit(extra_summary)] ||= []) << package.customer
        end
      end
    end
  end

  def dump_current_extras(distributor)
    @current_extras ||= distributor.extras
  end

private

  def extras_count(extra, _extras_summary)
    @extras_count_store[name_with_unit(extra)] || 0
  end

  def extras_customers(extra)
    customers = @extras_customers_store[name_with_unit(extra)] || []
    customers.sort_by!(&:name)

    names = customers.uniq.map do |customer|
      count = customers.count(customer)
      count > 1 ? "#{customer.name} (x#{count})" : customer.name
    end.join(", ")

    emails = customers.uniq.map(&:email).join(", ")

    { names: names, emails: emails }
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
