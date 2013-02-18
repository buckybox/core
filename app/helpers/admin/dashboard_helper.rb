module Admin::DashboardHelper
  def distributors_next_delivery_date(distributor)
    next_occurrence = distributor.customers.ordered_by_next_delivery.select(:next_order_occurrence_date).first.try(:next_order_occurrence_date)
    if next_occurrence.blank? || next_occurrence < Date.current
      nil
    elsif next_occurrence == Date.current
      'Today'
    elsif next_occurrence == Date.current.tomorrow
      'Tomorrow'
    elsif next_occurrence && (next_occurrence < (Date.current + 6.days))
      next_occurrence.to_s(:weekday)
    elsif next_occurrence
      next_occurrence.to_s(:day_month_and_year)
    end
  end
end
