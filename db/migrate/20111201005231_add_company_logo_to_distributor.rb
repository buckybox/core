class AddCompanyLogoToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :company_logo, :string
  end
end
