def daily_orders(distributor, n = 3)
  daily_order_schedule = Schedule.new
  daily_order_schedule.add_recurrence_rule(IceCube::Rule.daily)

  n.times do
    customer = Fabricate(:customer, distributor: distributor)
    Fabricate(:active_order, account: customer.account, schedule: daily_order_schedule)
  end
end
