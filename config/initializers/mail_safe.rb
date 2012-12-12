if defined?(MailSafe::Config)
  MailSafe::Config.internal_address_definition = lambda { |address|
    address =~ /.*@buckybox\.com/i
  }

  MailSafe::Config.replacement_address = 'beta@buckybox.com'
end
