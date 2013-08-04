Fabricator(:distributor) do
  name { sequence(:name) { |i| "Distributor #{i}" } }
  email { sequence(:email) { |i| "distributor#{i}@example.com" } }
  password 'password'
  password_confirmation { |attrs| attrs[:password] }
  country
  consumer_delivery_fee_cents 0
  send_email true
  send_halted_email true
end

Fabricator(:distributor_with_information, from: :distributor) do
  invoice_information
  bank_information
end

Fabricator(:distributor_a_customer, from: :distributor) do
  after_create {|distributor| distributor.customers << Fabricate(:customer, distributor: distributor)}
end

Fabricator(:distributor_with_everything, from: :distributor_with_information) do
  after_create do |distributor|
    %w(Grapes Avocado).each do |item|
      Fabricate(:line_item, distributor: distributor, name: item)
    end

    Fabricate(:customisable_box, distributor: distributor)
    Fabricate(:route, distributor: distributor)
    Fabricate(:customer, distributor: distributor)

    distributor.active_webstore = true

    distributor.save!
  end
end
