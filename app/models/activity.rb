class Activity < ActiveRecord::Base
  def self.add(params)
    initiator = case params.fetch(:initiator)
      when Customer
        params[:initiator].name
      when Distributor
        "You"
      else
        raise
    end

    options = params.fetch(:options)

    create!(
      customer_id: params.fetch(:customer).id,
      action: "#{initiator} paused their order of <em>#{options[:order].box.name}</em> starting #{options[:order].pause_date.strftime("%a %d %b")}"
    )
  end
end

