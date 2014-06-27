class DeviseMailer < Devise::Mailer
protected

  def headers_for(action, opts)
    distributor = if resource.respond_to?(:distributor)
      resource.distributor
    else
      resource
    end

    opts.merge!(
      'X-Mailer' => Figaro.env.x_mailer,
      'From'     => distributor.email_from(email: Figaro.env.no_reply_email),
      'Reply-To' => distributor.support_email,
    )

    super(action, opts)
  end
end
