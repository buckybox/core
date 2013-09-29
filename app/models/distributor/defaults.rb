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
    populate_email_templates
    distributor.save
  end

private

  attr_accessor :distributor

  def populate_line_items
    LineItem.add_defaults_to(distributor)
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

  #TODO: Figure out the best way to move the email content below into a config file

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
      subject: "Using your login for ordering at #{distributor_name}",
      body: <<-BODY
Hi {first_name},

you can keep up to date with your orders by logging into your account with us here:
#{customer_login_url}

Use this account to:
- Make or change orders
- Check your transaction history
- Pause your deliveries
- Update your delivery address

SETTING UP A PASSWORD
If you do not have a password or have forgotten it, you can request a new password by using this link below:
#{customer_reset_password_url}

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
