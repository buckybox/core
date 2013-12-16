class Activity < ActiveRecord::Base
  def self.add(customer, initiator, type, params = {})
    params[:initiator] = case initiator
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

private

  ACTIONS = {
    order_pause: ->(params) {
      "#{params.initiator} paused their order of #{params.order.box.name} starting #{params.order.pause_date.strftime("%a %d %b")}"
    },
    order_remove_pause: ->(params) {
      "#{params.initiator} unpaused their order of #{params.order.box.name}"
    },
    order_resume: ->(params) {
      "#{params.initiator} updated their order of #{params.order.box.name} to resume on #{params.order.resume_date.strftime("%a %d %b")}"
    },
    order_remove_resume: ->(params) {
      "#{params.initiator} updated their order of #{params.order.box.name} to no longer resume"
    },
    order_update_extras: ->(params) {
      "#{params.initiator} changed the extras for their order of #{params.order.box.name}"
    },
    order_remove_extras: ->(params) {
      "#{params.initiator} updated their order of #{params.order.box.name} to no longer include extras"
    },
    order_add_extras: ->(params) {
      "#{params.initiator} added some extras for their order of #{params.order.box.name}"
    },
    order_update_box: ->(params) {
      "#{params.initiator} changed their order from #{params.old_box_name} to a #{params.order.box.name}"
    },
    order_update_frequency: ->(params) {
      "#{params.initiator} changed the frequency of #{params.order.box.name} from #{params.old_frequency} to #{params.order.schedule_rule.frequency}"
    },
    order_remove: ->(params) {
      "#{params.initiator} removed their order of #{params.order.box.name}"
    },
  }
end

