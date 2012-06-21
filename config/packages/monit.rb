MONIT_CONFIG_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'configs', 'monit', 'configuration'))
MONIT_SCRIPT_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'configs', 'monit', 'script'))

package :monit, :provides => :monitoring do
  describe 'Monitor processes, files, devices and remote systems'
  apt 'monit'
  
  tmp_file = "/tmp/monit"

  push_text File.read(MONIT_SCRIPT_PATH), tmp_file do
    post :install, "mv #{tmp_file} /etc/default/monit"
  end
  push_text File.read(MONIT_CONFIG_PATH), tmp_file do
    post :install, "mv #{tmp_file} /etc/monit/monitrc"
    post :install, "chown -R root:root /etc/monit"
    post :install, "/etc/init.d/monit restart"
  end

  verify do
    has_executable 'monit'
  end
end
