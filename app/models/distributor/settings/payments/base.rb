class Distributor::Settings::Payments::Base
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  def initialize(args)
    @distributor = args.fetch(:distributor)
    @bank_information = distributor.bank_information || distributor.create_bank_information
  end

  def errors
    (@bank_information.distributor.errors.values | @bank_information.errors.values).flatten
  end

  def persisted?
    false
  end

protected

  attr_reader :distributor, :bank_information
end
