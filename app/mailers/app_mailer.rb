class AppMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  default 'X-Mailer' => Figaro.env.x_mailer
end
