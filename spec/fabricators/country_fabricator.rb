Fabricator(:country) do
  alpha2 "NZ"
  default_consumer_fee_cents 10

  before_validation do |new_country|
    # make sure there is only one unique instance of each country,
    # deleting the existing one if present so it validates
    existing_country = Country.find_by_alpha2(new_country.alpha2)
    existing_country.delete if existing_country
  end
end
