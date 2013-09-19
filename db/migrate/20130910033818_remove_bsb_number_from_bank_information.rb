class RemoveBsbNumberFromBankInformation < ActiveRecord::Migration
  class BankInformation < ActiveRecord::Base; end

  def up
    BankInformation.all.each do |bank_information|
      sanitised_bsb_number = sanitise_number(bank_information.bsb_number)
      sanitised_account_number = sanitise_number(bank_information.account_number)
      new_account_number = [sanitised_bsb_number, sanitised_account_number].join

      bank_information.account_number = new_account_number
      bank_information.save!(validate: false)
    end

    remove_column :bank_information, :bsb_number
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def sanitise_number(string)
    string.to_s.gsub(/[^0-9]/, '')
  end
end
