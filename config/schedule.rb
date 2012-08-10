# Use this file to easily define all of your cron jobs.
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron
# Learn more: http://github.com/javan/whenever

set :output, { :error => 'log/cron_error.log', :standard => 'log/cron.log' }

every '0 * * * *' do
  runner 'Jobs.run_all'
end

#TODO we are not doing invoicing at the moment
#every 1.day, :at => '6am' do
#  runner 'CronLog.log("Generating and sending out invoices if needed.")'
#  runner 'Invoice.generate_invoices'
#end
