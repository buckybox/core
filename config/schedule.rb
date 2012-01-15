# Use this file to easily define all of your cron jobs.
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
# Learn more: http://github.com/javan/whenever

every 1.day, :at => '4am' do
  runner 'Order.deactivate_finished', :output => {
    :error => 'log/deactivate_finished_cron_error.log',
    :standard => 'log/deactivate_finished_cron.log'
  }
end

every 1.day, :at => '4am' do
  runner 'Order.create_next_delivery', :output => {
    :error => 'log/create_next_delivery_cron_error.log',
    :standard => 'log/create_next_delivery_cron.log'
  }
end

