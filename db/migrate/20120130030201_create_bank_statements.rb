class CreateBankStatements < ActiveRecord::Migration
  def change
    create_table :bank_statements do |t|
      t.references :distributor
      t.string :statement_file

      t.timestamps
    end
    add_index :bank_statements, :distributor_id
  end
end
