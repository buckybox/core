class EmailForm < Form
  attr_accessor :body, :subject, :preview_email
  include ActiveModel::Validations

  validates :body, :subject, presence: true

  def initialize(opts)
    self.subject = opts[:subject]
    self.body = opts[:body]
    self.preview_email = opts[:preview_email]
  end

  def send!
    if valid?
      DistributorMailer.raise_errors do
        DistributorMailer.update_email(self).deliver
      end
      true
    else
      false
    end
  end

  def send_preview!
    if valid? && preview_email_present?
      AdminMailer.raise_errors do
        AdminMailer.preview_email(self).deliver
      end
      true
    else
      false
    end
  end

  def preview_email_present?
    if preview_email.present? && !preview_email.match(Devise.email_regexp).nil?
      true
    else
      errors.add(:preview_email, 'is required')
      false
    end
  end
end
