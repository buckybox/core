class Distributor::Defaults
  def self.populate_defaults(distributor)
    defaults = new(distributor)
    defaults.populate_defaults
  end

  def initialize(distributor)
    @distributor = distributor
  end

  def populate_defaults
    populate_line_items
    populate_bank_information
    populate_paypal_information
    populate_email_templates
    distributor.save
  end

private

  attr_accessor :distributor

  def populate_line_items
    LineItem.add_defaults_to(distributor)
  end

  def populate_bank_information
    bank_information = distributor.bank_information || distributor.create_bank_information

    banks = distributor.omni_importers.bank_deposit
    bank_information.name = banks.first.bank_name unless banks.empty?
    bank_information.account_name = distributor.name
    bank_information.cod_payment_message = "Please place payment in your mailbox."

    bank_information.save(validate: false) # because model is missing account number
  end

  def populate_paypal_information
    distributor.paypal_email = distributor.email
  end

  def populate_email_templates
    distributor.email_templates = email_templates
  end

  def email_templates
    templates.map { |template| EmailTemplate.new(template[:subject], template[:body]) }
  end

  def templates
    [
      account_overdue_email,
      login_for_ordering_email,
      weekly_newsleter_email,
    ]
  end

  def customer_login_url
    url_helper.new_customer_session_url(host: app_host, distributor: distributor_parameter_name)
  end

  def customer_reset_password_url
    url_helper.new_customer_password_url(host: app_host, distributor: distributor_parameter_name)
  end

  def distributor_name
    distributor.name
  end

  def distributor_parameter_name
    distributor.parameter_name
  end

  def app_host
    Figaro.env.host
  end

  def url_helper
    Rails.application.routes.url_helpers
  end

  # TODO: Figure out the best way to move the email content below into a config file

  def account_overdue_email
    {
      subject: "Your account is overdue",
      body: <<-BODY
Hi {first_name},

Just a reminder that your account balance is overdue.

Your existing balance is: {account_balance}

You can login to your account to check your account history and make payments here:
#{customer_login_url}

Cheers
-The team at #{distributor_name}
      BODY
    }
  end

  def login_for_ordering_email
    {
      subject: "Accessing your account on our new online ordering system",
      body: <<-BODY
Hi {first_name},

We've migrated onto a new online ordering system called Bucky Box.

In order to access your account on Bucky Box please follow the steps below to set up your password.

1) Click this link: #{customer_reset_password_url}

2) Enter your email address we have on record: {email_address}

3) An email message will be sent to you with a "Change my password" link. Clicking this will let you assign yourself a password and you'll be able to access your dashboard immediately.

You can log into your account at anytime to:
- Check your transaction history
- Make or change orders
- Pause your deliveries
- Update your delivery address

Cheers
-The team at #{distributor_name}
      BODY
    }
  end

  def weekly_newsleter_email
    {
      subject: "Weekly Newsletter - What's in your box this week",
      body: <<-BODY
Hi {first_name},

Thanks for supporting.

WHAT'S IN YOUR BOX THIS WEEK

As you know, we source the best seasonal produce from around the region, so here's some of the delicious fresh items you might find in your box this week;
- INSERT PRODUCE LIST HERE

TOP RECIPE TIPS

Here's our top 3 recipes which include some of the ingredients you have to cook with:
- ADD RECIPE LINKS HERE

BITE SIZE KNOWLEDGE

A key part of what drives us is creating a thriving, diverse food system - it's better for people and planet.

As part of that vision we scour the markets, farms and seedbanks for interesting produce which we add to your delivery.

This week's lesser-known food stuff is INSERT FOOD ITEM HERE, AND A LITTLE INFORMATION ABOUT IT.

FEEDBACK

We love to hear your thoughts, good or bad, about how your experience with us is going. We strive to give you the best food delivery service around, so your insights are vital to us improving.

Drop us an email, tweet (@twitterhandle) or call anytime and we'll get back to you.

Thank you for your loyal custom and for supporting a better food system.

OWNER/CUSTOMER SERVICE NAME
#{distributor_name}
CONTACT DETAILS
      BODY
    }
  end
end
