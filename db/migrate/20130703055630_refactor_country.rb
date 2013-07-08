class RefactorCountry < ActiveRecord::Migration
  def up
    add_column :countries, :alpha2, :string, limit: 2, null: false, default: ""
    add_index :countries, :alpha2

    # data from http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
    {
      "Argentina" => "AR",
      "AU" => "AU",
      "Belgium" => "BE",
      "Brazil" => "BR",
      "Canada" => "CA",
      "China" => "CN",
      "Germany" => "DE",
      "HK" => "HK",
      "India" => "IN",
      "Indonesia" => "ID",
      "Ireland" => "IE", # Internet Explorer :P
      "Israel" => "IL",
      "Italy" => "IT",
      "Kenya" => "KE",
      "Mexico" => "MX",
      "NZ" => "NZ",
      "South Africa" => "ZA",
      "Spain" => "ES",
      "Sweden" => "SE",
      "Thailand" => "TH",
      "Turkey" => "TR",
      "UK" => "GB",
      "US" => "US",
    }.each do |country, code|
      country = Country.where(name: country).first
      country.alpha2 = code
      country.save!
    end

    raise "Country ISO codes are missing" unless Country.where(alpha2: "").empty?

    remove_column :countries, :default_currency
    remove_column :countries, :default_time_zone
    remove_column :countries, :full_name
    remove_column :countries, :name
    Country.reset_column_information

    coutries_with_boggus_currency = %w(AQ GG IM JE MM TV)
    countries = ISO3166::Country.all.map(&:last) - coutries_with_boggus_currency

    countries.each do |code|
      country = Country.where(alpha2: code).first
      unless country
        c = Country.new(alpha2: code)
        c.save! if c.iso3166.currency # skip if no currency for this country
      end
    end
  end

  def down
    remove_column :countries, :alpha2
  end
end
