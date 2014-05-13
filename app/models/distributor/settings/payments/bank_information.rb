# NOTE: not to be used directly, designed to be inherited
class Distributor::Settings::Payments::BankInformation < Distributor::Settings::Payments::Base
  def initialize(args)
    super
    @bank_information = distributor.bank_information || distributor.create_bank_information
  end

  def errors
    (@bank_information.distributor.errors.values | @bank_information.errors.values).flatten
  end

protected

  attr_reader :bank_information
end

