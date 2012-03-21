module Devise::RequestHelpers
  def simulate_distributor_sign_in
    @distributor = Fabricate(:distributor)
    visit new_distributor_session_path
    fill_in 'Email', :with => @distributor.email
    fill_in 'Password', :with => @distributor.password
    click_button 'Sign in'
  end

  def simulate_customer_sign_in
    @customer = Fabricate(:customer)
    visit new_customer_session_path
    fill_in 'Email', :with => @customer.email
    fill_in 'Password', :with => @customer.password
    click_button 'Sign in'
  end
end

