package :cron_apt do

  apt "cron-apt"

  local = File.join(File.dirname(__FILE__), 'configs', 'cron-apt', 'config')
  tmp = "/tmp/cron-apt.config"
  remote = "/etc/cron-apt/config"
  transfer local, tmp do
    post :install, "mv #{tmp} #{remote}"
  end

  verify do
    has_apt "cron-apt"
  end

end

