class ActionMailer::Base
  def self.raise_errors(&block)
    original_value = ActionMailer::Base.raise_delivery_errors
    ActionMailer::Base.raise_delivery_errors = true
    begin
      yield
    ensure
      ActionMailer::Base.raise_delivery_errors = original_value
    end
  end
end
