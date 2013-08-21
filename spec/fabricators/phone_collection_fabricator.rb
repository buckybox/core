Fabricator(:phone_collection) do
  on_init { init_with Fabricate(:full_address) }
end
