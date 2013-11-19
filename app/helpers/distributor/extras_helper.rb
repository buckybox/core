module Distributor::ExtrasHelper
  def extras_limit_collection
    1.upto(10).each_with_object({}) do |i, h|
      h["Allow up to #{pluralize(i, "item")}"] = i
    end.merge!("Allow any number of items" => -1) # eek!
  end

  def box_items_limit_collection
    1.upto(7).each_with_object({}) do |i, h|
      h["limited to #{pluralize(i, "item")}"] = i
    end.merge!("without limits" => 0) # eek!
  end

  def all_extras_collection
    { "entire catalog" => 1, "items below" => 0 }
  end
end
