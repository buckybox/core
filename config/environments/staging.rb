load Rails.root.join("config/environments/production.rb")

BuckyBox::Application.configure do
  config.action_mailer.smtp_settings[:domain] = 'staging.buckybox.com'

  # ActiveMerchant setup as test only
  config.after_initialize do
    ActiveMerchant::Billing::Base.mode = :test
  end
end


