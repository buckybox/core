class Devise::CustomFailureApp < Devise::FailureApp

  def respond
    if params.key?(:customer)
      info = params[:customer]
      info[:password_hash] = Digest::SHA1.hexdigest info.delete(:password)

      send_login_failure_email info
    end

    super
  end

private

  def send_login_failure_email info
    AdminMailer.delay(
      priority: Figaro.env.delayed_job_priority_low,
      queue: "#{__FILE__}:#{__LINE__}",
    ).information_email(
      to: "sysadmins@buckybox.com",
      subject: "Login failure!",
      body: info.inspect,
    )
  end

end
