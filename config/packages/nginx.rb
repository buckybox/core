# Monkey patch to md5 check from as string, not a file
module Md5Text
  Sprinkle::Verify.register(Md5Text)
  def matches_text(text, remotefile, mode=nil)
    require 'digest/md5'
    local = Digest::MD5.hexdigest(text)
    @commands << %{[ "X$(md5sum #{remotefile}|cut -d\\  -f 1)" = "X#{local}" ]}
  end
end

# Monkey patch to make echo not put new line char on end
module Sprinkle
  module Installers
    class PushText < Installer
      protected
      def install_commands #:nodoc:
        "#{"#{'sudo ' if option?(:sudo)}grep \"^#{@text.gsub("'", "'\\\\''").gsub("\n", '\n')}$\" #{@path} ||" if option?(:idempotent) }/bin/echo -ne '#{@text.gsub("'", "'\\\\''").gsub("\n", '\n')}' |#{'sudo ' if option?(:sudo)}tee -a #{@path}"
      end
    end
  end
end

package :nginx do
    
  config_file = "/usr/local/nginx/conf/nginx.conf"
  config_text = Package.preprocess_stage(File.read(File.join(File.dirname(__FILE__), 'configs', 'nginx', 'nginx.conf')))
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
    post :install, "#{init_file} restart"
  end
  
  verify do
    matches_text(config_text, config_file)
    matches_text(config_text, config_file) #Not sure why this needs to be called twice, but it does..
  end
end

