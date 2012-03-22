module ApplicationHelper
  def order_schedule(order, options = {})
    joiner = (options[:join_with].nil? ? '<br/>' : options[:join_with])
    schedule = order.schedule
    string_schedule = []

    unless options[:recurrence_rules] == false || schedule.recurrence_rules.empty?
      string_schedule << schedule.recurrence_rules.join(', ')
    end

    unless options[:recurrence_times] == false || schedule.recurrence_times.empty?
      string_schedule << 'Single delivery order'
    end

    unless options[:exception_rules] == false || schedule.exception_rules.empty?
      string_schedule << schedule.exception_rules.join(', ')
    end

    unless options[:exception_times] == false || schedule.exception_times.empty?
      et = schedule.exception_times
      first_et = et.first
      last_et = (et.last + 1.day) # this is shown as the resume day so a day after the last exception date
      exception_times = "pausing on #{first_et.to_s(:month_date_year)}#{joiner}resuming on #{last_et.to_s(:month_date_year)}".html_safe
      string_schedule << "#{link_to exception_times, '#', data: {'reveal-id' => "pause-modal-#{order.id}"}}"
    end

    return string_schedule.join(joiner).html_safe
  end
end
