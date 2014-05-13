class Distributor::Settings::Payments::Base
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  def initialize(args)
    @distributor = args.fetch(:distributor)
  end

  def errors
    [] # may be overridden by other classes
  end

  def persisted?
    false
  end

protected

  attr_reader :distributor
end
