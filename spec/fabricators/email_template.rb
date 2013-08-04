Fabricator(:email_template) do
  on_init do
    init_with "Hi customer!", "What's up [first_name]?"
  end
end

