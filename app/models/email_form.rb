require 'action_mailer'
require_relative 'form'
require 'active_model/validations'
require 'active_model/translation'


class EmailForm < Form
  attr_accessor :body, :subject, :preview_email
  include ActiveModel::Validations

  validates :body, :subject, presence: true

  def initialize(opts)
    self.subject = opts[:subject]
    self.body = opts[:body]
    self.preview_email = opts[:preview_email]
  end

  def send!(to=::Distributor.keep_updated)
    if valid?
      to.each do |distributor|
        DistributorMailer.delay(
          priority: Figaro.env.delayed_job_priority_high,
          queue: "#{__FILE__}:#{__LINE__}",
        ).update_email(self, distributor)
      end
      true
    else
      false
    end
  end

  #distributor or admin is passed if, both respond to name
  def mail_merge(distributor=nil)
    raise "#{distributor} must respond to :contact_name" unless distributor.respond_to?(:contact_name)
    self.body.gsub(/\[\[name\]\]/, distributor.contact_name)
  end

  def send_preview!
    if valid? && preview_email_present?
      AdminMailer.raise_errors do
        AdminMailer.preview_email(self, OpenStruct.new(contact_name: preview_email)).deliver
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
