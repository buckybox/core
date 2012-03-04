class AddSupportEmailToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :support_email, :string

  end
end
