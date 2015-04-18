class Devise::CustomFailureApp < Devise::FailureApp

  def respond
    if params.key?(:customer)
      details = params[:customer].dup
      details[:password_hash] = Digest::SHA1.hexdigest details.delete(:password)
      CronLog.log("Login failure for #{details[:email]}", details.inspect)

      Librato.increment_async "bucky.customer.sign_in.failure.from_failure_app"
      Librato.increment_async "bucky.customer.sign_in.failure.total"
    end

    super
  end

end
