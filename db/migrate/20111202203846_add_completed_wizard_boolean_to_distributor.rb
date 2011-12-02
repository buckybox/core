class AddCompletedWizardBooleanToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :completed_wizard, :boolean, :default => false, :null => false
  end
end
