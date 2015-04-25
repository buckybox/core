class Activity < ActiveRecord::Base
  ACTIONS = {
    order_pause: lambda do |params|
      "#{params.initiator} paused their order of #{params.order.box.name} starting #{params.order.pause_date.strftime("%a %d %b")}"
    end,
    order_remove_pause: lambda do |params|
      "#{params.initiator} unpaused their order of #{params.order.box.name}"
    end,
    order_resume: lambda do |params|
      "#{params.initiator} updated their order of #{params.order.box.name} to resume on #{params.order.resume_date.strftime("%a %d %b")}"
    end,
    order_remove_resume: lambda do |params|
      "#{params.initiator} updated their order of #{params.order.box.name} to no longer resume"
    end,
    order_update_extras: lambda do |params|
      "#{params.initiator} changed the extras for their order of #{params.order.box.name}"
    end,
    order_remove_extras: lambda do |params|
      "#{params.initiator} updated their order of #{params.order.box.name} to no longer include extras"
    end,
    order_add_extras: lambda do |params|
      "#{params.initiator} added some extras for their order of #{params.order.box.name}"
    end,
    order_update_box: lambda do |params|
      "#{params.initiator} changed their order from #{params.old_box_name} to a #{params.order.box.name}"
    end,
    order_update_frequency: lambda do |params| # XXX for future use - the UI doesn't allow to update this yet
      "#{params.initiator} changed the frequency of #{params.order.box.name} from #{params.old_frequency} to #{params.order.schedule_rule.frequency}"
    end,
    order_remove: lambda do |params|
      "#{params.initiator} removed their order of #{params.order.box.name}"
    end,
    order_create: lambda do |params|
      message = "#{params.initiator} created an order of #{params.order.box.name}"
      message << " with extras" if params.order.extras.present?
      message
    end,
  }

  def self.add(customer, initiator, type, params = {})
    params[:initiator] = \
    case initiator
    when Customer
      initiator.name
    when Distributor
      "You"
    else
      raise ArgumentError, "Invalid initiator"
    end

    action = ACTIONS.fetch(type).call(
      OpenStruct.new(params)
    )

    create!(
      customer_id: customer.id,
      action: action,
    )
  end
end

