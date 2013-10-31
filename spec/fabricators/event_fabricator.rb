Fabricator(:event) do
  event_type { :new_webstore_customer }
  message { "New webstore customer" }
  distributor

  after_build do |event|
    event.set_key(Fabricate(:customer))
  end
end
