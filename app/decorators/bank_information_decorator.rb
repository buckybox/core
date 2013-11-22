class BankInformationDecorator < Draper::Decorator
  delegate_all

  delegate :name, :account_name, to: :bank, prefix: true

  def bank_account_number
    SimpleForm::Inputs::BankAccountNumberInput.formatted_bank_account_number(
      bank.account_number, bank.country.alpha2
    )
  end

  def note
    customer_message
  end

  def customer_number
    context[:customer].customer_number
  end

  def bank
    object
  end
end

