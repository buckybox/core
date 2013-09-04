class Distributor::Settings::Payments::Base
  def initialize(args)
    distributor = args.fetch(:distributor)
    @bank_information = distributor.bank_information || BankInformation.new
  end

protected

  attr_reader :bank_information
end
