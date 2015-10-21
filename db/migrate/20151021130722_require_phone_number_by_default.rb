class RequirePhoneNumberByDefault < ActiveRecord::Migration
  def change
    change_column :distributors, :collect_phone, :boolean, default: true, null: false
    change_column :distributors, :require_phone, :boolean, default: true, null: false
  end
end
