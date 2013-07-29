class DeviseMailer < Devise::Mailer
protected

  def headers_for(action, opts)
    custom_opts = {
      'X-Mailer' => Figaro.env.x_mailer,
    }
    opts.merge!(custom_opts)

    super(action, opts)
  end
end
