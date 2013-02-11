class AddSendEmailOptionsToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :send_email, :boolean
    add_column :distributors, :send_halted_email, :boolean
  end
end
