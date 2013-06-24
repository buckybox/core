class AddEmailTemplatesToDistributor < ActiveRecord::Migration
  def up
    add_column :distributors, :email_templates, :text

    templates = [
      {
        subject: "Your account is overdue",
        body: "Hi [first-name],\n\nJust a reminder that your balance is overdue.\n\nCheers"
      },
      {
        subject: "Newsletter",
        body: "Hi [first-name],\n\nGreat news today!"
      },
    ].map do |template|
      t = EmailTemplate.new
      t.subject = template[:subject]
      t.body = template[:body]

      t
    end

    serialized_templates = EmailTemplate.new.dump(templates).freeze

    Distributor.update_all(email_templates: serialized_templates)
  end

  def down
    remove_column :distributors, :email_templates
  end
end
