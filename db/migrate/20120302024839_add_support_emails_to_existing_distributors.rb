class AddSupportEmailsToExistingDistributors < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end

  def up
    Distributor.reset_column_information

    Distributor.all.each do |distributor|
      support_email = distributor.read_attribute(:support_email)

      if support_email.blank?
        email = distributor.read_attribute(:email)
        distributor.update_attribute(:support_email, email)
      end
    end
  end

  def down
    # Can not rollback this data migration
  end
end
