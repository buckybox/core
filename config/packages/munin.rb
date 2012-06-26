package :munin, :provides => :reporting do
  describe 'Provide graphs as to the history of the systems resources'
  apt 'munin munin-node munin-plugins-extra'
  
  verify do
    has_file '/etc/munin/munin.conf'
  end
end

