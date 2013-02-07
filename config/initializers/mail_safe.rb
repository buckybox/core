if defined?(MailSafe::Config)
  MailSafe::Config.internal_address_definition = lambda { |address|
    address =~ /.*@buckybox\.com/i ||
    address =~ /.*@enspiral\.com/i ||
    address == 'support@buckybox.com'
  }

  MailSafe::Config.replacement_address = 'beta@buckybox.com'
end
