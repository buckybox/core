module Admin::DistributorsHelper
  ERROR_CLASS = 'text-error'
  PASS_CLASS = ''

  def delivery_service_status(delivery_service)
    delivery_service.blank? ? ERROR_CLASS : PASS_CLASS
  end

  def order_status(delivery_service, box)
    raise "Need to complete this method"
  end

  def box_type_status(distributor, box)
    distributor.boxes.find_by_name(box.box_type).blank? ? ERROR_CLASS : PASS_CLASS
  end

  def extras_status(distributor, extras, box)
    box = distributor.find_box_from_import(box)
    if box.blank? || box.extras_unlimited? || box.extras_limit >= extras.collect(&:count).sum
      PASS_CLASS
    else
      ERROR_CLASS
    end
  end

  def extra_status(distributor, extra, box=nil)
    distributor.find_extra_from_import(extra, box).blank? ? ERROR_CLASS : PASS_CLASS
  end

  def show_extra(distributor, extra, box=nil)
    (found_extra = distributor.find_extra_from_import(extra, box)).present? ? "#{extra.count}x #{found_extra.name_with_price(0)}" : extra.to_s
  end
end
