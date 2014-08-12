module PaypalForm

module_function

  def recurring_payment_params(schedule_rule)
    # https://www.paypal.com/en/cgi-bin/webscr?cmd=_pdn_subscr_techview_outside
    # p3 - number of time periods between each recurrence
    # t3 - time period (D=days, W=weeks, M=months, Y=years)

    p3, t3 = if schedule_rule.weekly?
      [1, "W"]
    elsif schedule_rule.fortnightly?
      [2, "W"]
    elsif schedule_rule.monthly?
      [1, "M"]
    else
      raise ArgumentError, "Invalid ScheduleRule for recurring_payment_params: #{schedule_rule.inspect}"
    end

    OpenStruct.new(p3: p3, t3: t3).freeze
  end
end
