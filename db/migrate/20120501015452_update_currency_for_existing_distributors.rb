class UpdateCurrencyForExistingDistributors < ActiveRecord::Migration
  class Account < ActiveRecord::Base; end
  class Box < ActiveRecord::Base; end
  class Distributor < ActiveRecord::Base; end
  class Extra < ActiveRecord::Base; end
  class Invoice < ActiveRecord::Base; end
  class Package < ActiveRecord::Base; end
  class Payment < ActiveRecord::Base; end
  class Route < ActiveRecord::Base; end
  class Transaction < ActiveRecord::Base; end

  # This is a one off migration specific to the distributors of the time 
  # all future ones should be created with currencies
  def up
    Account.reset_column_information
    Box.reset_column_information
    Distributor.reset_column_information
    Extra.reset_column_information
    Invoice.reset_column_information
    Package.reset_column_information
    Payment.reset_column_information
    Route.reset_column_information
    Transaction.reset_column_information

    distributor_currencies = [
      [:nzd, 'beta@buckybox.com'],
      [:nzd, 'demo@buckybox.com'],
      [:nzd, 'info@greenjuiceinc.co.nz'],
      [:nzd, 'richard@organicboxes.co.nz'],
      [:nzd, 'support@buckybox.com'],
      [:nzd, 'thefield@orcon.net.nz'],
      [:aud, 'foodbox@foodgarden.com.au'],
      [:hkd, 'jack.foodwaste@example.com'],
      [:hkd, 'jack.foodwaste@gmail.com'],
      [:gbp, 'info@redearthorganics.co.uk'],
      [:gbp, 'ritawild@communitybuyingni.com'],
      [:usd, 'john@organicfood2you.com'],
      [:usd, 'marshall@farmtobabynyc.com']
    ]

    distributor_currencies.each { |currency, email| convert_currency_to(currency, email) }
  end

  def down
    # Could roll back this data but not worth it
  end

  private

  def convert_currency_to(currency, distributor_email)
    #----- Distributor model itself
    distributor = Distributor.find_by_email(distributor_email)

    if distributor
      distributor_id = distributor.read_attribute(:id)
      distributor.update_attributes(currency: currency, invoice_threshold_currency: currency)

      #----- Models that belong directly to distributors
      boxes = Box.find_all_by_distributor_id(distributor_id)
      boxes.each { |box| box.update_attribute(:currency, currency) }

      extras = Extra.find_all_by_distributor_id(distributor_id)
      extras.each { |extra| extra.update_attribute(:currency, currency) }

      payments = Payment.find_all_by_distributor_id(distributor_id)
      payments.each { |payment| payment.update_attribute(:currency, currency) }

      routes = Route.find_all_by_distributor_id(distributor_id)
      routes.each { |route| route.update_attribute(:currency, currency) }

      #----- Models that belong to distributors directly
      customers = Customer.find_all_by_distributor_id(distributor_id)
      customer_ids = customers.map(&:id)

      accounts = Account.find_all_by_customer_id(customer_ids)
      accounts.each { |account| account.update_attribute(:currency, currency) }
      account_ids = accounts.map(&:id)

      invoices = Invoice.find_all_by_account_id(account_ids)
      invoices.each { |invoice| invoice.update_attribute(:currency, currency) }

      transactions = Transaction.find_all_by_account_id(account_ids)
      transactions.each { |transaction| transaction.update_attribute(:currency, currency) }

      #----- The lonely model that accociates through the packing list
      packing_lists = PackingList.find_all_by_distributor_id(distributor_id)
      packing_list_ids = packing_lists.map(&:id)

      packages = Package.find_all_by_packing_list_id(packing_list_ids)
      packages.each { |packing| packing.update_attributes(archived_price_currency: currency, archived_fee_currency: currency) }
    end
  end
end

