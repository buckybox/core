module Devise::CustomControllerParameters
  def self.included(base)
    base.before_filter :setup_custom_variables
  end

  private

  def setup_custom_variables
    @distributor = Distributor.find_by_parameter_name(params[:distributor]) if params[:distributor]

    if @distributor.nil? && params[:customer] && params[:customer][:email]
      customer = Customer.find_by_email(params[:customer][:email])
      @distributor = customer.distributor unless customer.nil?
    end

    if @distributor
      @abort_url = webstore_store_path(@distributor.parameter_name)
      @abort_text = 'go to webstore'
      @link_args = { distributor: @distributor.parameter_name }
    else
      @abort_url = Figaro.env.marketing_site_url
      @abort_text = "go to #{Figaro.env.marketing_site_url}"
      @link_args = nil
    end
  end
end
