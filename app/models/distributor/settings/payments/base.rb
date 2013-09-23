class Distributor::Settings::Payments::Base
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  def initialize(args)
    distributor = args.fetch(:distributor)
    @bank_information = distributor.bank_information || distributor.create_bank_information
  end

  def persisted?
    false
  end

protected

  attr_reader :bank_information
end
