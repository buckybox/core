def daily_orders(distributor, n = 3)
  n.times do
    customer = Fabricate(:customer, distributor: distributor)
    customer.account.route.stub_chain(:schedule, :include?).and_return(true) # I admit this is a hack to get around having to have valid Route.schedules but there is a lot of tests failing and I need to move on
    Fabricate(:active_order, account: customer.account, schedule_rule: ScheduleRule.weekly(Date.current, ScheduleRule::DAYS))
  end
end
