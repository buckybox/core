class Admin::CronLogsController < Admin::ResourceController
  actions :index

  protected

  def collection
    @cron_logs ||= end_of_association_chain.limit(250)
  end
end

