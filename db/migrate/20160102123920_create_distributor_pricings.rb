class CreateDistributorPricings < ActiveRecord::Migration
  def change
    create_table :distributor_pricings do |t|
      t.belongs_to :distributor, index: true

      t.string :name, null: false
      t.integer :flat_fee_cents, null: false, default: 0
      t.decimal :percentage_fee, null: false, default: 0
      t.integer :percentage_fee_max_cents, null: false, default: 0
      t.decimal :discount_percentage, null: false, default: 0
      t.string :currency, null: false

      t.timestamps
    end

    Distributor.find_each do |distributor|
      defaults = Distributor::Defaults.new(distributor)
      defaults.send :populate_pricing
    end
  end
end
