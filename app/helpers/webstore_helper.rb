module WebstoreHelper
  def phone_types_collection
    Address::PhoneCollection::TYPES.each_key.map do |type|
      [
        "#{type.capitalize} phone",
        type
      ]
    end
  end
end
