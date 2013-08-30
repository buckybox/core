class DistributorTracking
  def initialize(distributor)
    @distributor = distributor
  end

  def tracking_after_create
    comms_tracking.create_user(tracking_data, Rails.env)
  end

  def tracking_after_save
    delay(
      priority: Figaro.env.delayed_job_priority_low
    ).update_tags
  end

  def track(action_name, occurred_at = Time.current, env = Rails.env)
    comms_tracking.track(distributor.id, action_name, occurred_at, env)
  end

private

  attr_reader :distributor

  def tracking_data
    {
      user_id:     distributor.id,
      email:       distributor.email,
      name:        distributor.contact_name,
      created_at:  distributor.created_at,
      custom_data: {
        business_name: distributor.name,
        phone:        distributor.phone,
      }
    }
  end

  def update_tags
    comms_tracking.update_tags({id: distributor.id, tag_list: distributor.tag_list}, Rails.env)
  end

  def comms_tracking
    Bucky::CommsTracking.instance
  end
end

def p(order)
  start = Date.parse("2013-08-26")
  fin = Date.parse("2013-09-02")
  if order.paused? && (order.schedule_rule.schedule_pause.finish.present? && order.schedule_rule.schedule_pause.finish > start)
    start = order.schedule_rule.schedule_pause.start > start ? start : order.schedule_rule.schedule_pause.start
    fin = !order.schedule_rule.schedule_pause.finish.nil? && order.schedule_rule.schedule_pause.finish < fin ? fin : order.schedule_rule.schedule_pause.finish
  end
  fin = nil if order.schedule_rule.schedule_pause.finish.nil?
  #"#{start} -> #{fin} \t #{order.schedule_rule.schedule_pause.start if order.paused?} -> #{order.schedule_rule.schedule_pause.finish if order.paused?}"
  order.pause!(start,fin)
end
puts d.orders.active.collect{|o| p(o)}
