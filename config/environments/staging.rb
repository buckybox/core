load Rails.root.join("config/environments/production.rb")

BuckyBox::Application.configure do
  config.action_mailer.smtp_settings[:domain] = 'staging.buckybox.com'

  # ActiveMerchant setup as test only
  config.after_initialize do
    ActiveMerchant::Billing::Base.mode = :test
  end

  config.middleware.use(Oink::Middleware)

  config.middleware.use(StackProf::Middleware,
    enabled: true,
    mode: :wall,
    interval: 1000,
    save_every: 20,
    path: Rails.root.join("tmp"),
  )
end

