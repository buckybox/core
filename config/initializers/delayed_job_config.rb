Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.delay_jobs = Rails.env.production? || Rails.env.staging? # Run inline for testing
Delayed::Worker.max_attempts = 8 # Default setting means jobs will be retried up to 30 days later, not ideal.

require 'delayed-plugins-airbrake'
Delayed::Worker.plugins << Delayed::Plugins::Airbrake::Plugin
