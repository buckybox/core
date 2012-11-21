class TurnOffIntoTourForSomeDistributors < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end

  def up
    Distributor.reset_column_information
    distributor_names = ['Veggie Van of Mudgee', 'Organic Boxes']

    distributor_names.each do |distributor_name|
      distributor = Distributor.find_by_name(distributor_name)

      unless distributor.nil?
        distributor.update_attributes!(
          customers_show_intro: false, 
          deliveries_index_packing_intro: false, 
          deliveries_index_deliveries_intro: false, 
          payments_index_intro: false, 
          customers_index_intro: false
        )
      end
    end
  end

  def down
    # Not worth it
  end
end
