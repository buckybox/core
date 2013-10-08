class Distributor::ResourceController < Distributor::BaseController
  inherit_resources

  protected

  def begin_of_association_chain
    current_distributor
  end

  def email
    link_action = params[:link_action]
    link_action = "send" if link_action.empty?

    message = if (link_action == "delete")
      email_templates_update(link_action)

    else
      return error("Oops") unless params[:email_template]

      email_template = EmailTemplate.new(
        params[:email_template][:subject],
        params[:email_template][:body]
      )

      if !email_template.valid?
        return error(email_template.errors.join('<br>'))
      end

      email_templates_update(link_action, email_template)
    end

    if message && current_distributor.save
      flash[:notice] = message if link_action == "send"
      render json: { link_action => true, message: message }
    else
      return error(current_distributor.errors.full_messages)
    end
  end

  def get_email_templates
    @email_templates = current_distributor.email_templates
  end

  def email_templates_update action, email_template = nil
    selected_email_template_id = params[:selected_email_template_id].to_i
    recipient_ids = params[:recipient_ids].split(',').map(&:to_i)
    message = nil

    case action
    when "update"
      current_distributor.email_templates[selected_email_template_id] = email_template
      message = "Your changes have been saved."

    when "delete"
      deleted = current_distributor.email_templates.delete_at(selected_email_template_id)
      message = "Email template <em>#{deleted.subject}</em> has been deleted."

    when "save"
      current_distributor.email_templates << email_template
      message = "Your new email template <em>#{email_template.subject}</em> has been saved."

    when "preview"
      customer = Customer.find recipient_ids.first
      personalised_email = email_template.personalise(customer)
      CustomerMailer.email_template(current_distributor, personalised_email).deliver
      message = "A preview email has been sent to #{current_distributor.email}."

    when "send"
      if params[:commit]
        message = send_email recipient_ids, email_template

        tracking.event(current_distributor, "sent_group_email") unless current_admin.present?
      end
    end

    message
  end

  def send_email recipient_ids, email
    recipient_ids.each do |id|
      customer = Customer.find id
      personalised_email = email.personalise(customer)

      CustomerMailer.delay(
        priority: Figaro.env.delayed_job_priority_high
      ).email_template(customer, personalised_email)
    end

    message = "Your email \"#{email.subject}\" is being sent to "
    message << if recipient_ids.size == 1
      Customer.find(recipient_ids.first).name
    else
      "#{recipient_ids.size} customers"
    end
    message << "..."
  end
end

