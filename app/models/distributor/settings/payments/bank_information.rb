# NOTE: not to be used directly, designed to be inherited
class Distributor::Settings::Payments::BankInformation < Distributor::Settings::Payments::Base
  def initialize(args)
    super
    @bank_information = distributor.bank_information || distributor.create_bank_information
  end

  def errors
    distributor_errors = @bank_information.distributor.errors
    distributor_errors.empty? or return distributor_errors

    bank_information_errors = @bank_information.errors
    bank_information_errors.empty? or return bank_information_errors

    super
  end

protected

  attr_reader :bank_information
end
