module Devise::CustomControllerParameters
  def self.included(base)
    base.before_filter :setup_custom_variables
  end

  private

  def setup_custom_variables
    @distributor = Distributor.find_by_parameter_name(params[:distributor])

    if @distributor
      @abort_url = webstore_store_path(@distributor.parameter_name)
      @abort_text = 'go to webstore'
      @link_args = { distributor: @distributor.parameter_name }
    else
      @abort_url = 'http://www.buckybox.com/'
      @abort_text = 'go to buckybox.com'
      @link_args = nil
    end
  end
end
