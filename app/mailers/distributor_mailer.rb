class DistributorMailer < ApplicationMailer
  def welcome(distributor)
    @distributor = distributor

    mail to: @distributor.email_to,
         from: "Will Lau <#{Figaro.env.support_email}>",
         subject: "#{@distributor.name}, welcome to Bucky Box!"
  end

  def bank_setup(distributor, bank_name)
    @distributor = distributor
    @bank_name = bank_name

    mail to: @distributor.email_to,
         from: "Bucky Box Support <#{Figaro.env.support_email}>",
         subject: "[Bucky Box] Setting up your bank feed"
  end
end
