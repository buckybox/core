class DeviseMailer < Devise::Mailer
protected

  def headers_for(action, opts)
    opts = {
      'X-Mailer' => Figaro.env.x_mailer,
    }.merge(opts)

    super(action, opts)
  end
end
