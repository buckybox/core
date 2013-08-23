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

  def track(action_name, occurred_at=Time.current, env = Rails.env)
    comms_tracking.track(distributor.id, action_name, occurred_at, env)
  end

private

  def tracking_data
    {user_id: distributor.id, email: distributor.email, name: distributor.name,
     created_at: distributor.created_at,
     custom_data: {contact_name: distributor.contact_name, phone: distributor.phone}}
  end

  def update_tags
    comms_tracking.update_tags({id: distributor.id, tag_list: distributor.tag_list}, Rails.env)
  end

  def comms_tracking
    Bucky::CommsTracking.instance
  end

  def distributor
    @distributor
  end
end
