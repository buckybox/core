module Devise::CustomControllerParameters
  def self.included(base)
    base.before_filter :setup_custom_variables
  end

private

  def setup_custom_variables
    @distributor = Distributor.find_by_parameter_name(params[:distributor]) if params[:distributor]

    if @distributor.nil? && params[:customer] && params[:customer][:email]
      customers = Customer.where(email: params[:customer][:email])

      if customers.one?
        @distributor = customers.first.distributor

      elsif customers.count > 1
        message = "You must use one of these links:<ul><li>" <<
          customers.map do |customer|
            distributor = customer.distributor

            view_context.link_to distributor.name, new_customer_session_url(distributor: distributor.parameter_name)
          end.join("<li>") << "</ul>"

        flash.now[:alert] = message.html_safe
      end
    end

    @link_args = @distributor ? { distributor: @distributor.parameter_name } : nil
    @distributor_id = @distributor ? @distributor.id : 0
  end
end
