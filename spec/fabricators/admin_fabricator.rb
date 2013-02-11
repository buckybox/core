Fabricator(:admin) do
  email { sequence(:email) { |i| "admin#{i}@example.com" } }
  password 'password'
  password_confirmation { |attrs| attrs[:password] }
end
