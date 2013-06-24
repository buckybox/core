class AddEmailTemplatesToDistributor < ActiveRecord::Migration
  def up
    add_column :distributors, :email_templates, :text

    templates = [
      {
        subject: "Your account is overdue",
        body: "Hi [first_name],\n\nJust a reminder that your balance is overdue.\n\nCheers"
      },
      {
        subject: "Newsletter",
        body: "Hi [first_name],\n\nGreat news today!"
      },
    ].map do |template|
      EmailTemplate.new template[:subject], template[:body]
    end.freeze

    # NOTE: I could simply assign `email_templates` for each distributor but it
    # takes more than a minute so I use the following hack:
    coder = ActiveRecord::Coders::YAMLColumn.new Array
    serialized_templates = coder.dump(templates).freeze

    Distributor.update_all(email_templates: serialized_templates)
  end

  def down
    remove_column :distributors, :email_templates
  end
end
