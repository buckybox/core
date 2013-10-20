# Use this file to easily define all of your cron jobs.
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
# Learn more: http://github.com/javan/whenever

set :output, { :error => 'log/cron_error.log', :standard => 'log/cron.log' }

every '0 * * * *' do
  runner 'Jobs.run_hourly'
end
every '0 1 * * *' do
  runner 'Jobs.run_daily'
end

