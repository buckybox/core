class AddPolymorphicAssocciationsToTransactions < ActiveRecord::Migration
  class Transaction < ActiveRecord::Base; end

  def up
    Transaction.reset_column_information

    add_column :transactions, :transactionable_id, :integer
    add_column :transactions, :transactionable_type, :string

    # by kind and discription figure out transaction
    Transaction.all.each do |transaction|
      kind        = transaction.read_attribute(:kind)
      description = transaction.read_attribute(:description)

      kind = (kind == 'amend' ? 'Account' : kind.classify) if kind

      if kind == 'Account' && description
        id = transaction.read_attribute(:account_id)
      elsif description
        # For string "[ID#504] Recieved a payment by bank transfer."
        # For string "[ID#504] Delivery was made of Fruit Box at 5.00."
        matched_data = /^\[ID#([^)]+)\].(.+)$/.match(description)

        id           = matched_data[1].to_i
        description  = matched_data[2] # Keep the description but without the id
      end

      if id && kind
        transaction.update_attributes!(
          transactionable_id:   id,
          transactionable_type: kind,
          description:          description
        )
      end
    end

    remove_column :transactions, :kind
  end

  def down
    add_column :transactions, :kind, :string

    # Could roll back data but not worth it

    remove_column :transactions, :transactionable_id
    remove_column :transactions, :transactionable_type
  end
end
