Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.delay_jobs = Rails.env.production? || Rails.env.staging? # Run inline for testing
