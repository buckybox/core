class Devise::CustomFailureApp < Devise::FailureApp
  def respond
    if params.key?(:customer)
      details = params[:customer].dup
      password = details.delete(:password) || ""
      details[:password_hash] = Digest::SHA1.hexdigest password
      CronLog.log("Login failure for #{details[:email]}", details.inspect)

      Librato.increment "bucky.customer.sign_in.failure.from_failure_app"
      Librato.increment "bucky.customer.sign_in.failure.total"
    end

    super
  end
end
