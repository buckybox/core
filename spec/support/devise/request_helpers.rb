module Devise::RequestHelpers
  include Warden::Test::Helpers

  def distributor_sign_in
    @distributor = Fabricate(:distributor)
    visit new_distributor_session_path
    fill_in 'Email', :with => @distributor.email
    fill_in 'Password', :with => @distributor.password
    click_button 'Sign in'
  end

  def customer_sign_in
    @customer = Fabricate(:customer)
    visit new_customer_session_path
    fill_in 'Email', :with => @customer.email
    fill_in 'Password', :with => @customer.password
    click_button 'Sign in'
  end

  def login_customer(customer)
    @last_login = :customer
    login_as customer, scope: :customer
  end

  def login_distributor(distributor)
    @last_login = :distributor
    login_as distributor, scope: :distributor
  end

  def dump_html(html)
    File.open('test_dump.html', 'w') {|f| f.write(html) }
    `lynx -dump -width 120 test_dump.html > output.txt`
    puts `cat output.txt`
  ensure
    File.delete('test_dump.html')
  end
end
