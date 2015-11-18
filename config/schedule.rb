# Learn more: http://github.com/javan/whenever

# *     *     *   *    *
# -     -     -   -    -
# |     |     |   |    |
# |     |     |   |    +----- day of week (0 - 6) (Sunday=0)
# |     |     |   +------- month (1 - 12)
# |     |     +--------- day of        month (1 - 31)
# |     +----------- hour (0 - 23)
# +------------- min (0 - 59)

set :output, { error: "log/cron_error.log", standard: "log/cron.log" }

every "0 * * * *" do
  runner "Jobs.run_hourly"
end

every "0 0 * * *" do
  runner "Jobs.run_daily"
end

every "0 0 * * 0" do
  runner "Jobs.run_weekly"
end
