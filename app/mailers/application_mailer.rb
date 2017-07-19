class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  default 'X-Mailer' => Figaro.env.x_mailer

  def default_url_options
    @default_url_options ||= if Rails.env.production?
      { protocol: "https", host: Figaro.env.host }
    else
      super
    end
  end
end
