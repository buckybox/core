module Devise::RequestHelpers
  include Warden::Test::Helpers
  Warden.test_mode!

  def self.included(base)
    base.after { Warden.test_reset! }
  end

  def admin_login
    @admin ||= Fabricate(:admin)
    @last_login = :admin
    login_as @admin, scope: :admin
  end

  def distributor_login
    @distributor ||= Fabricate(:distributor)
    @last_login = :distributor
    login_as @distributor, scope: :distributor
  end

  def customer_login
    @customer ||= Fabricate(:customer)
    @last_login = :customer
    login_as @customer, scope: :customer
  end

  def pretty_html(html)
    File.open('test_dump.html', 'w') {|f| f.write(html) }
    `lynx -dump -width 120 test_dump.html > output.txt`
    puts `cat output.txt`
  ensure
    File.delete('test_dump.html')
  end
end
