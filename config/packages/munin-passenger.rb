MUNIN_PASSENGER_STATUS_CONFIG_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'configs', 'munin', 'passenger_status'))
MUNIN_PASSENGER_MEMORY_CONFIG_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'configs', 'munin', 'passenger_memory_stats'))
MUNIN_NODE = File.expand_path(File.join(File.dirname(__FILE__), 'configs', 'munin', 'munin-node'))

package :munin_passenger, :provides => :monitoring do
  describe 'Add passenger to munin'
  requires :munin
  tmp_file = '/tmp/munin'

  push_text File.read(MUNIN_NODE), tmp_file do
    post :install, "su -c 'cat #{tmp_file} >> /etc/munin/plugin-conf.d/munin-node'"
  end

  push_text File.read(MUNIN_PASSENGER_STATUS_CONFIG_PATH), tmp_file do
    post :install, "mv #{tmp_file} /usr/share/munin/plugins/passenger_status"
    post :install, 'chmod a+x /usr/share/munin/plugins/passenger_status'
    post :install, 'ln -sf /usr/share/munin/plugins/passenger_status /etc/munin/plugins/passenger_status'
  end

  push_text File.read(MUNIN_PASSENGER_MEMORY_CONFIG_PATH), tmp_file do
    post :install, "mv #{tmp_file} /usr/share/munin/plugins/passenger_memory_stats"
    post :install, 'chmod a+x /usr/share/munin/plugins/passenger_memory_stats'
    post :install, 'ln -sf /usr/share/munin/plugins/passenger_memory_stats /etc/munin/plugins/passenger_memory_stats'
    post :install, 'su -c \'echo "munin   ALL=(ALL) NOPASSWD:/usr/bin/passenger-status, /usr/bin/passenger-memory-stats" >> /etc/sudoers\''
    post :install, 'restart munin-node'
  end
  
  verify do
    has_symlink '/etc/munin/plugins/passenger_status'
    has_symlink '/etc/munin/plugins/passenger_memory_stats'
  end
end
