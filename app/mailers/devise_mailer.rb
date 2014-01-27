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
      'From'     => distributor.support_email,
      'Reply-To' => distributor.support_email,
    )

    super(action, opts)
  end
end
