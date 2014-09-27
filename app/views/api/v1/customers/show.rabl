object @customer

attributes :id, :first_name, :last_name, :name, :email, :delivery_service_id, :halted?, :discount?, :discount

attribute :formated_number => :number

node(:account_balance) { |customer| customer.account.balance.to_s }
node(:webstore_id) { |customer| customer.distributor.parameter_name }

unless @embed['address'].nil?
  child :address do
    attributes :address_1, :address_2, :suburb, :city, :postcode, :delivery_note,
      :home_phone, :mobile_phone, :work_phone
  end
end
