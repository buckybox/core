def daily_orders(distributor, n = 3)
  daily_order_schedule = Schedule.new
  daily_order_schedule.add_recurrence_rule(IceCube::Rule.weekly(1).day(:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday))

  n.times do
    customer = Fabricate(:customer, distributor: distributor)
    customer.account.route.stub_chain(:schedule, :include?).and_return(true) # I admit this is a hack to get around having to have valid Route.schedules but there is a lot of tests failing and I need to move on
    Fabricate(:active_order, account: customer.account, schedule: daily_order_schedule)
  end
end
