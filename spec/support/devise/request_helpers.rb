module Devise::RequestHelpers
  include Warden::Test::Helpers

  def sign_in_as_a_valid_customer(customer = nil)
    @customer = customer || Fabricate(:customer)
    login_customer @customer
  end

  def sign_in_as_a_valid_distributor(distributor = nil)
    @distributor = distributor || Fabricate(:distributor_with_everything)
    login_distributor @distributor
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
