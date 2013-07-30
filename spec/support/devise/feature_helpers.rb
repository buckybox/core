module Devise::FeatureHelpers
  def simulate_admin_sign_in
    @admin ||= Fabricate(:admin)
    visit new_admin_session_path
    fill_in 'admin[email]', with: @admin.email
    fill_in 'admin[password]', with: @admin.password
    click_button 'Login'
  end

  def simulate_distributor_sign_in
    @distributor ||= Fabricate(:distributor)
    visit new_distributor_session_path
    fill_in 'distributor[email]', with: @distributor.email
    fill_in 'distributor[password]', with: @distributor.password
    click_button 'Login'
  end

  def simulate_customer_sign_in
    @customer ||= Fabricate(:customer)
    visit new_customer_session_path
    fill_in 'customer[email]', with: @customer.email
    fill_in 'customer[password]', with: @customer.password
    click_button 'Login'
  end
end

