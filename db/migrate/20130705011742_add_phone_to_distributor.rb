class AddPhoneToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :phone, :string
  end
end
