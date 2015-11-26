collection @webstores

cache @webstores.map(&:cache_key)

attributes :name, :webstore_url
node(:postal_address) { |webstore| webstore.localised_address.postal_address_without_recipient }
node(:ll) { |webstore| webstore.localised_address.ll }

