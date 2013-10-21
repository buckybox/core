class Distributor::ResourceController < Distributor::BaseController
  inherit_resources

  protected

  def begin_of_association_chain
    current_distributor
  end

  def get_email_templates
    @email_templates = current_distributor.email_templates
  end
end

