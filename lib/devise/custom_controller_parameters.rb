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

    if @distributor
      @abort_url = webstore_store_path(@distributor.parameter_name)
      @abort_text = "go to web store"
      @link_args = { distributor: @distributor.parameter_name }
    else
      @abort_url = Figaro.env.marketing_site_url
      @abort_text = "go to #{Figaro.env.marketing_site_url}"
      @link_args = nil
    end

    @distributor_id = @distributor ? @distributor.id : nil
  end
end
