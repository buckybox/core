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
      exception_times = "pausing on #{et.first.strftime("%B %d")}#{joiner}resuming on #{et.last.strftime("%B %d")}".html_safe
      string_schedule << "#{link_to exception_times, '#', data: {'reveal-id' => "pause-modal-#{order.id}"}}"
    end

    return string_schedule.join(joiner).html_safe
  end
end
