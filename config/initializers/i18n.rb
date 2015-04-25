if Rails.env.development? || Rails.env.test?
  I18n.exception_handler = lambda do |_exception, locale, key, _options|
    raise "Missing translation for locale #{locale}: #{key}"
  end
end
