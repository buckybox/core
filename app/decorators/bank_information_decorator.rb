class BankInformationDecorator < Draper::Decorator
  delegate_all

  delegate :name, :account_name, :account_number, to: :bank, prefix: true

  def note
    customer_message
  end

  def customer_number
    nil
  end

  def bank
    object
  end
end

