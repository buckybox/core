package :passenger, :provides => :appserver do
  description 'Phusion Passenger (mod_rails)'
  version '3.0.13'
  binaries = %w(passenger-config passenger-install-nginx-module passenger-install-apache2-module passenger-make-enterprisey passenger-memory-stats passenger-status)
  
  gem 'passenger', :version => version do    
    # Install nginx and the module
    #binaries.each {|bin| post :install, "ln -s usr/local/ruby/bin/#{bin} /usr/local/bin/#{bin}"}
    post :install, "sudo passenger-install-nginx-module --auto --auto-download --prefix=/usr/local/nginx"
    post :install, "echo ** Nginx installed by passenger gem **"
  end
  
  requires :ruby, :passenger_requirements
  
  verify do
    has_gem "passenger", version
    binaries.each {|bin| has_file "/usr/local/bin/#{bin}" }
  end
end

package :passenger_requirements do
  apt 'libcurl4-openssl-dev'
  
  verify do
    has_apt 'libcurl4-openssl-dev'
  end
end
