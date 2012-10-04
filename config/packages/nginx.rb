package :nginx_config do
    
  config_file = "/usr/local/nginx/conf/nginx.conf"
  config_text = Package.preprocess_stage(File.read(File.join(File.dirname(__FILE__), 'configs', 'nginx', 'nginx.conf')))
  init_file = "/etc/init.d/nginx"
  tmp_file = "/tmp/nginx"

  push_text(config_text, tmp_file) do
    post :install, "mv #{tmp_file} #{config_file}"
    post :install, "mkdir -p /usr/local/nginx/sites-available"
    post :install, "mkdir -p /usr/local/nginx/sites-enabled"
    post :install, "mkdir -p /var/log/nginx"
    post :install, "#{init_file} restart"
  end

  verify do
    matches_local(config_text, config_file)
  end
end

package :nginx_initd do
  
  init_text = File.read(File.join(File.dirname(__FILE__), 'configs', 'nginx', 'init.d'))
  init_file = "/etc/init.d/nginx"
  tmp_file = "/tmp/nginx"

  push_text init_text, tmp_file do
    post :install, "mv #{tmp_file} #{init_file}"
    post :install, "chmod +x #{init_file}"
    post :install, "/usr/sbin/update-rc.d -f nginx defaults"
    post :install, "#{init_file} start"
  end
  
  verify do
    matches_local(init_text, init_file)
  end
end

package :nginx do
  requires :nginx_initd
  requires :nginx_config
end
