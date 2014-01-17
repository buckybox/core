class DeviseMailer < Devise::Mailer
protected

  def headers_for(action, opts)
    opts.merge!(
      'X-Mailer' => Figaro.env.x_mailer,
      'From'     => resource.distributor.support_email,
      'Reply-To' => resource.distributor.support_email,
    )

    super(action, opts)
  end
end
