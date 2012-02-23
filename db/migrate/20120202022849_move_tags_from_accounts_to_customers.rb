class MoveTagsFromAccountsToCustomers < ActiveRecord::Migration
  class Account < ActiveRecord::Base; end
  class Customer < ActiveRecord::Base; end
  class ActsAsTaggableOn::Tagging < ActiveRecord::Base; end

  def up
    Account.reset_column_information
    Customer.reset_column_information
    ActsAsTaggableOn::Tagging.reset_column_information

    ActsAsTaggableOn::Tagging.all.each do |tagging|
      if tagging.taggable_type == 'Account'
        account = Account.find_by_id(tagging.taggable_id)
        customer = Customer.find_by_id(account.customer_id) if account

        if account && customer
          tagging.update_attributes!(taggable_type:'Customer', taggable_id:customer.id)
        end
      end
    end
  end

  def down
    Account.reset_column_information
    Customer.reset_column_information
    ActsAsTaggableOn::Tagging.reset_column_information

    ActsAsTaggableOn::Tagging.all.each do |tagging|
      if tagging.taggable_type == 'Customer'
        customer = Customer.find_by_id(tagging.taggable_id)
        account = Account.find_by_customer_id(customer.id) if customer

        if customer && account
          tagging.update_attributes!(taggable_type:'Account', taggable_id:account.id)
        end
      end
    end
  end
end
