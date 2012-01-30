# Use this file to easily define all of your cron jobs.
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
# Learn more: http://github.com/javan/whenever

set :output, { :error => 'log/cron_error.log', :standard => 'log/cron.log' }

every 1.hour do
  runner 'Distributor.create_daily_lists'
end

every 1.hour do
  runner 'Distributor.automate_completed_status'
end

every 1.day do
  runner 'Order.deactivate_finished'
end

