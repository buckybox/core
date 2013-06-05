module WebstoreHelper
  def phone_types_collection
    PhoneCollection::TYPES.each_key.map do |type|
      [
        type.capitalize,
        type
      ]
    end
  end
end
