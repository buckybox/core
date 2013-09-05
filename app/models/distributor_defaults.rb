class DistributorDefaults
  class << self
    def populate_defaults(distributor)
      populate_line_items(distributor)
      populate_bank_information(distributor)
    end

  private

    def populate_line_items(distributor)
      LineItem.add_defaults_to(distributor)
    end

    def populate_bank_information(distributor)
      bank_information = distributor.bank_information || distributor.create_bank_information
      bank_information.name = distributor.omni_importers.bank_deposit.first.bank_name
      bank_information.account_name = distributor.contact_name
      bank_information.save(validate: false) # because model is missing account & BSB numbers
    end
  end
end
