class AddEmailTemplatesToDistributor < ActiveRecord::Migration
  def up
    add_column :distributors, :email_templates, :text

    Distributor.all.each do |distributor|
      email_templates = [
        {
          subject: "Your account is overdue",
          body: <<-BODY
Hi {first_name},

Just a reminder that your account balance is overdue.

Your existing balance is: {account_balance}

You can login to your account to check your account history and make payments here:
#{Rails.application.routes.url_helpers.new_customer_session_url(host: Figaro.env.host, distributor: distributor.parameter_name)}

Cheers
-The team at #{distributor.name}
          BODY
        },
        {
          subject: "Using your login for ordering at #{distributor.name}",
          body: <<-BODY
Hi {first_name},

you can keep up to date with your orders by logging into your account with us here:
#{Rails.application.routes.url_helpers.new_customer_session_url(host: Figaro.env.host, distributor: distributor.parameter_name)}

Use this account to:
- Make or change orders
- Check your transaction history
- Pause your deliveries
- Update your delivery address

SETTING UP A PASSWORD
If you do not have a password or have forgotten it, you can request a new password by using this link below:
#{Rails.application.routes.url_helpers.new_customer_password_url(host: Figaro.env.host, distributor: distributor.parameter_name)}

Cheers
-The team at #{distributor.name}
          BODY
        },
      ].map do |template|
        EmailTemplate.new template[:subject], template[:body]
      end.freeze

      # NOTE: I could simply assign `email_templates` for each distributor but it
      # takes more than a minute so I use the following hack:
      coder = ActiveRecord::Coders::YAMLColumn.new Array
      serialized_templates = coder.dump(email_templates).freeze

      distributor.update_column 'email_templates', serialized_templates
    end
  end

  def down
    remove_column :distributors, :email_templates
  end
end
