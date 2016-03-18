class AddInvoicingDayOfTheMonthToDistributorPricing < ActiveRecord::Migration
  def change
    add_column :distributor_pricings, :invoicing_day_of_the_month, :integer, null: false, default: 1

    Distributor::Pricing.update_all(invoicing_day_of_the_month: 10)
  end
end
