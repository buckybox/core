package :redis_server do
  describe 'Redis Key-Value Store'

  apt 'redis-server'

  verify do
    has_apt 'redis-server'
  end
end

package :redis_config do
  describe 'Redis Key-Value Store Config'

  remote_file = "/etc/redis/redis.conf"
  local_file = File.expand_path(File.join(File.dirname(__FILE__), 'configs', 'redis', 'redis.conf'))
  tmp_file = "/tmp/redis"

  push_text(File.read(local_file), tmp_file) do
    post :install, "mv #{tmp_file} #{remote_file}"
    post :install, "chown root:root #{remote_file}"
    post :install, "/etc/init.d/redis-server restart"
  end

  verify do
    matches_local(local_file, remote_file)
  end
end

package :redis do
  requires :redis_server
  requires :redis_config
end
