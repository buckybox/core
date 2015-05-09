if Rails.env.development? || Rails.env.test?
  Bullet.enable = true
  # Bullet.alert = true
  Bullet.bullet_logger = true
  # Bullet.console = true
  Bullet.rails_logger = true
  # Bullet.bugsnag = true
  Bullet.add_footer = true
  # Bullet.stacktrace_includes = [ 'your_gem', 'your_middleware' ]
  # Bullet.slack = { webhook_url: 'http://some.slack.url', foo: 'bar' }
end
