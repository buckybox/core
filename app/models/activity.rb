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

    action = ACTIONS.fetch(type).call(params)

    create!(
      customer_id: customer.id,
      action: action,
    )
  end

private

  ACTIONS = {
    order_pause: ->(params) {
      "#{params[:initiator]} paused their order of <em>#{params[:order].box.name}</em> starting #{params[:order].pause_date.strftime("%a %d %b")}"
    },
    order_remove_pause: ->(params) {
      "#{params[:initiator]} unpaused their order of <em>#{params[:order].box.name}</em>"
    },

  }
end

