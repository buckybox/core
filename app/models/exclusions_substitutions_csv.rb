class ExclusionsSubstitutionsCsv
  include Singleton

  def self.generate(date, orders)
    instance.generate(date, orders)
  end

  def generate(date, orders)
    exclusions_substitutions = count_exclusions_substitutions(orders)

    CSV.generate do |csv|
      headers(csv, orders)

      exclusions_substitutions.map do |line_item, boxes|
        boxes_exclusions_substitutions = boxes.sort_by(&:first).map do |_box, e_s|
          [ e_s[:exclusions], e_s[:substitutions] ]
        end.flatten

        csv << [
          line_item,
          date.iso8601,
          total_exclusions_substitutions(boxes, :exclusions),
          total_exclusions_substitutions(boxes, :substitutions),
          *boxes_exclusions_substitutions
        ]
      end
    end
  end

  def headers(csv, orders)
    csv << [
      "",
      "delivery date",
      "total excludes",
      "total substitutes",
      *box_headers(orders)
    ]
  end

private

  def box_headers(orders)
    orders.map(&:box).uniq.sort_by(&:name).map do |box|
      %i(excludes substitutes).map do |line_item_type|
        "#{box.name} #{line_item_type}"
      end
    end.flatten
  end

  def count_exclusions_substitutions(orders)
    orders = orders.includes(:box, :exclusions, :substitutions)
    exclusions_substitutions = {}
    line_items = orders.first.distributor.line_items

    line_items.each do |line_item|
      line_item_name = line_item.name
      exclusions_substitutions[line_item_name] ||= {}

      orders.each do |order|
        box_name = order.box.name
        exclusions_substitutions[line_item_name][box_name] ||= {}

        %i(exclusions substitutions).each do |line_item_type|
          order_exclusions_substitutions = order.public_send(line_item_type)
          count = order_exclusions_substitutions.where(line_item_id: line_item.id).size

          # oh yeah that's ugly!
          exclusions_substitutions[line_item_name][box_name][line_item_type] ||= 0
          exclusions_substitutions[line_item_name][box_name][line_item_type] += count
        end
      end
    end

    exclusions_substitutions
  end

  def total_exclusions_substitutions(boxes, type)
    boxes.sum do |_box, exclusions_substitutions|
      exclusions_substitutions[type] || 0
    end
  end
end

