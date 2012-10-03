package :logrotate do
  description 'Setup log rotation for rails'

  config_text = File.read(File.join(File.dirname(__FILE__), 'configs', 'logrotate', 'rails')).gsub('#{RAILS_ENV}', Package.stage)
  tmp_file = "/tmp/logrotate"
  remote_file = '/etc/logrotate.d/rails'

  push_text(config_text, tmp_file) do
    post :install, "mv #{tmp_file} #{remote_file}"
  end

  verify do
    matches_local(config_text, remote_file)
  end
end
