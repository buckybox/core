Fabricator(:distributor) do
  name { sequence(:name) { |i| "Distributor #{i}" } }
  email { sequence(:email) { |i| "distributor#{i}@example.com" } }
  password 'password'
  password_confirmation { |attrs| attrs[:password] }
  country
  consumer_delivery_fee_cents 0
  send_email true
  send_halted_email true

  # Disable intros since we don't want them most of the time
  customers_index_intro false
  customers_show_intro false
  deliveries_index_packing_intro false
  deliveries_index_deliveries_intro false
  payments_index_intro false
end

Fabricator(:distributor_with_information, from: :distributor) do
  bank_information
end

Fabricator(:distributor_with_a_customer, from: :distributor) do
  after_create { |distributor| distributor.customers << Fabricate(:customer, distributor: distributor) }
end

Fabricator(:distributor_with_everything, from: :distributor_with_information) do
  before_create do |distributor|
    %w(Grapes Avocado).each do |item|
      Fabricate(:line_item, distributor: distributor, name: item)
    end

    Fabricate(:customisable_box,       distributor: distributor)
    Fabricate(:delivery_service,       distributor: distributor)
    Fabricate(:customer_with_address,  distributor: distributor)
    Fabricate(:localised_address,      addressable: distributor)

    distributor.active_webstore = true
    distributor.last_seen_at = Time.current

    distributor.save!
  end
end

Fabricator(:active_distributor_with_everything, from: :distributor_with_everything) do
  after_create do |distributor|
    10.times { Fabricate(:customer_with_transaction, distributor: distributor) }
  end
end

Fabricator(:existing_distributor_with_everything, from: :distributor_with_everything) do
  customers_index_intro false
  customers_show_intro false
  deliveries_index_deliveries_intro false
  deliveries_index_packing_intro false
  payments_index_intro false
end
