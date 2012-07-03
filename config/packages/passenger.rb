package :nginx, :provides => :webserver do
    
  config_file = "/usr/local/nginx/conf/nginx.conf"
  config_text = File.read(File.join(File.dirname(__FILE__), 'configs', 'nginx', 'nginx.conf')).gsub('#{RAILS_ENV}', Package.stage)
  init_file = "/etc/init.d/nginx"
  tmp_file = "/tmp/nginx"

  push_text(config_text, tmp_file) do
    post :install, "mv #{tmp_file} #{config_file}"
    post :install, "mkdir -p /usr/local/nginx/sites-available"
    post :install, "mkdir -p /usr/local/nginx/sites-enabled"
    post :install, "mkdir -p /var/log/nginx"
  end

  push_text File.read(File.join(File.dirname(__FILE__), 'configs', 'nginx', 'init.d')), tmp_file do
    post :install, "mv #{tmp_file} #{init_file}"
    post :install, "chmod +x #{init_file}"
    post :install, "/usr/sbin/update-rc.d -f nginx defaults"
    post :install, "#{init_file} start"
  end
  
  verify do
    has_executable "/usr/local/nginx/sbin/nginx"
    has_file init_file
    has_file config_file
    has_directory "/usr/local/nginx/sites-enabled"
    has_directory "/usr/local/nginx/sites-available"
    has_directory "/var/log/nginx"
  end
end

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
