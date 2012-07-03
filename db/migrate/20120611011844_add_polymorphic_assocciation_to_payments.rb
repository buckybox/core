class AddPolymorphicAssocciationToPayments < ActiveRecord::Migration
  class Paymant < ActiveRecord::Base; end

  def up
    Payment.reset_column_information

    add_column :payments, :payable_id, :integer
    add_column :payments, :payable_type, :string

    Payment.all.each do |payment|
      bsid = payment.read_attribute(:bank_statement_id)
      payment.update_attribute(:payable_id, bsid)
      payment.update_attribute(:payable_type, 'BankStatement')
    end

    remove_column :payments, :bank_statement_id
  end

  def down
    Payment.reset_column_information

    add_column :payments, :bank_statement_id, :integer

    Payment.all.each do |payment|
      pid = payment.read_attribute(:payable_id)
      ptype = payment.read_attribute(:payable_type)

      payment.update_attribute(bank_statement_id, pid) if ptype == 'BankStatement'
    end

    remove_column :payments, :payable_type
    remove_column :payments, :payable_id
  end
end
